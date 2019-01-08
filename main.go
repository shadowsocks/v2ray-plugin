package main

//go:generate errorgen

import (
	"flag"
	"fmt"
	"os"
	"os/signal"
	"path/filepath"
	"runtime"
	"strings"
	"syscall"

	"v2ray.com/core"
	"v2ray.com/core/common/platform"
	"v2ray.com/core/main/confloader"

	// The following are necessary as they register handlers in their init functions.

	// Required features. Can't remove unless there is replacements.
	_ "v2ray.com/core/app/dispatcher"
	_ "v2ray.com/core/app/proxyman/inbound"
	_ "v2ray.com/core/app/proxyman/outbound"

	// Default commander and all its services. This is an optional feature.
	// _ "v2ray.com/core/app/commander"
	// _ "v2ray.com/core/app/log/command"
	// _ "v2ray.com/core/app/proxyman/command"
	// _ "v2ray.com/core/app/stats/command"

	// Other optional features.
	// _ "v2ray.com/core/app/dns"
	_ "v2ray.com/core/app/log"
	// _ "v2ray.com/core/app/policy"
	// _ "v2ray.com/core/app/reverse"
	// _ "v2ray.com/core/app/router"
	// _ "v2ray.com/core/app/stats"

	// Inbound and outbound proxies.
	// _ "v2ray.com/core/proxy/blackhole"
	_ "v2ray.com/core/proxy/dokodemo"
	_ "v2ray.com/core/proxy/freedom"
	// _ "v2ray.com/core/proxy/http"
	// _ "v2ray.com/core/proxy/mtproto"
	// _ "v2ray.com/core/proxy/shadowsocks"
	_ "v2ray.com/core/proxy/socks"
	// _ "v2ray.com/core/proxy/vmess/inbound"
	// _ "v2ray.com/core/proxy/vmess/outbound"

	// Transports
	// _ "v2ray.com/core/transport/internet/domainsocket"
	// _ "v2ray.com/core/transport/internet/http"
	// _ "v2ray.com/core/transport/internet/kcp"
	_ "v2ray.com/core/transport/internet/quic"
	// _ "v2ray.com/core/transport/internet/tcp"
	// _ "v2ray.com/core/transport/internet/tls"
	// _ "v2ray.com/core/transport/internet/udp"
	_ "v2ray.com/core/transport/internet/websocket"

	// Transport headers
	// _ "v2ray.com/core/transport/internet/headers/http"
	// _ "v2ray.com/core/transport/internet/headers/noop"
	// _ "v2ray.com/core/transport/internet/headers/srtp"
	// _ "v2ray.com/core/transport/internet/headers/tls"
	// _ "v2ray.com/core/transport/internet/headers/utp"
	// _ "v2ray.com/core/transport/internet/headers/wechat"
	// _ "v2ray.com/core/transport/internet/headers/wireguard"

	// JSON config support. Choose only one from the two below.
	// The following line loads JSON from v2ctl
	// _ "v2ray.com/core/main/json"
	// The following line loads JSON internally
	_ "v2ray.com/core/main/jsonem"

	// Load config from file or http(s)
	_ "v2ray.com/core/main/confloader/external"
)

var (
	configFile = flag.String("config", "", "Config file for V2Ray.")
	version    = flag.Bool("version", false, "Show current version of V2Ray.")
	test       = flag.Bool("test", false, "Test config file only, without launching V2Ray server.")
	format     = flag.String("format", "json", "Format of input file.")
)

func fileExists(file string) bool {
	info, err := os.Stat(file)
	return err == nil && !info.IsDir()
}

func getConfigFilePath() string {
	if len(*configFile) > 0 {
		return *configFile
	}

	if workingDir, err := os.Getwd(); err == nil {
		configFile := filepath.Join(workingDir, "config.json")
		if fileExists(configFile) {
			return configFile
		}
	}

	if configFile := platform.GetConfigurationPath(); fileExists(configFile) {
		return configFile
	}

	return ""
}

func GetConfigFormat() string {
	switch strings.ToLower(*format) {
	case "pb", "protobuf":
		return "protobuf"
	default:
		return "json"
	}
}

func startV2Ray() (core.Server, error) {
	configFile := getConfigFilePath()
	configInput, err := confloader.LoadConfig(configFile)
	if err != nil {
		return nil, newError("failed to load config: ", configFile).Base(err)
	}
	defer configInput.Close()

	config, err := core.LoadConfig(GetConfigFormat(), configFile, configInput)
	if err != nil {
		return nil, newError("failed to read config file: ", configFile).Base(err)
	}

	server, err := core.New(config)
	if err != nil {
		return nil, newError("failed to create server").Base(err)
	}

	return server, nil
}

func printVersion() {
	version := core.VersionStatement()
	for _, s := range version {
		fmt.Println(s)
	}
}

func main() {
	flag.Parse()

	printVersion()

	if *version {
		return
	}

	server, err := startV2Ray()
	if err != nil {
		fmt.Println(err.Error())
		// Configuration error. Exit with a special value to prevent systemd from restarting.
		os.Exit(23)
	}

	if *test {
		fmt.Println("Configuration OK.")
		os.Exit(0)
	}

	if err := server.Start(); err != nil {
		fmt.Println("Failed to start", err)
		os.Exit(-1)
	}
	defer server.Close()

	// Explicitly triggering GC to remove garbage from config loading.
	runtime.GC()

	{
		osSignals := make(chan os.Signal, 1)
		signal.Notify(osSignals, os.Interrupt, os.Kill, syscall.SIGTERM)
		<-osSignals
	}
}
