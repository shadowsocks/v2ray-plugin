package main

//go:generate errorgen

import (
	"flag"
    "log"
	"os"
	"os/signal"
	"runtime"
	"strings"
	"syscall"

	"v2ray.com/core"

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
	vpn        = flag.Bool("vpn", false, "Run in VPN mode.")
    localAddr  = flag.String("localAddr",  "127.0.0.1",      "local address to listen on.")
    localPort  = flag.String("localPort",  "1984",           "local port to listen on.")
    remoteAddr = flag.String("remoteAddr", "127.0.0.1",      "remote address to forward.")
    remotePort = flag.String("remotePort", "1080",           "remote port to forward.")
    path       = flag.String("path",       "/",              "URL path for websocket.")
    host       = flag.String("host",       "cloudfront.com", "Host header for websocket.")
    server     = flag.Bool("server", false, "Run in server mode")

    clientConfig = `
{
	"inbounds": [{
		"listen": "<localAddr>",
		"port": <localPort>,
		"protocol": "dokodemo-door",
		"settings": {
			"address": "<localAddr>",
			"network": "tcp"
		}
	}],
	"outbounds": [{
		"protocol": "freedom",
		"mux":{
			"enabled":true,
			"concurrency":8
		},
		"settings": {
			"redirect": "<remoteAddr>:<remotePort>"
		},
		"streamSettings": {
			"network": "ws",
			"wsSettings": {
				"path": "<path>",
				"headers": {
					"Host": "<host>"
				}
			}
		}
	}]
}
`

	serverConfig = `
{
    "inbounds": [{
        "listen": "<localAddr>",
        "port": <localPort>,
        "protocol": "dokodemo-door",
        "settings": {
            "address": "v1.mux.cool",
            "network": "tcp"
        },
        "streamSettings": {
            "network": "ws",
            "wsSettings": {
                "path": "<path>",
                "headers": {
                    "Host": "<host>"
                }
            }
        }
    }],
    "outbounds": [{
        "protocol": "freedom",
        "settings": {
            "redirect": "<remoteAddr>:<remotePort>"
        }
    }]
}
`
)

func generateConfig() []byte {
	var configString string
	if *server {
		configString = serverConfig
	} else {
		configString = clientConfig
	}

	configString = strings.Replace(configString, "<localAddr>",  *localAddr,  -1)
	configString = strings.Replace(configString, "<localPort>",  *localPort,  -1)
	configString = strings.Replace(configString, "<remoteAddr>", *remoteAddr, -1)
	configString = strings.Replace(configString, "<remotePort>", *remotePort, -1)
	configString = strings.Replace(configString, "<host>",       *host,       -1)
	configString = strings.Replace(configString, "<path>",       *path,       -1)

	log.Println(configString)

	return []byte(configString)
}

func startV2Ray() (core.Server, error) {

    if *vpn {
        registerControlFunc()
    }

    opts, err := parseEnv()

    if err == nil {
        if c, b := opts.Get("host"); b {
            *host = c
        }
        if c, b := opts.Get("path"); b {
            *path = c
        }
        if _, b := opts.Get("server"); b {
			*server = true
        }
        if c, b := opts.Get("localAddr"); b {
			if *server{
				*remoteAddr = c
			} else {
				*localAddr = c
			}
        }
        if c, b := opts.Get("localPort"); b {
			if *server{
				*remotePort = c
			} else {
				*localPort = c
			}
        }
        if c, b := opts.Get("remoteAddr"); b {
			if *server{
				*localAddr = c
			} else {
				*remoteAddr = c
			}
        }
        if c, b := opts.Get("remotePort"); b {
			if *server{
				*localPort = c
			} else {
				*remotePort = c
			}
        }
    }

	configBytes := generateConfig();

    // Start the V2Ray instance.
	server, err := core.StartInstance("json", configBytes)
    if err != nil {
		return nil, newError("failed to create server").Base(err)
    }

	return server, nil
}

func printVersion() {
	version := core.VersionStatement()
	for _, s := range version {
		log.Println(s)
	}
}

func main() {
	flag.Parse()

    logInit()

	printVersion()

	server, err := startV2Ray()
	if err != nil {
		log.Println(err.Error())
		// Configuration error. Exit with a special value to prevent systemd from restarting.
		os.Exit(23)
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
