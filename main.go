package main

//go:generate errorgen

import (
	"flag"
	"log"
	"os"
	"os/signal"
	"strconv"
	"syscall"

	"github.com/golang/protobuf/proto"

	"v2ray.com/core"

	"v2ray.com/core/app/dispatcher"
	vLog "v2ray.com/core/app/log"
	"v2ray.com/core/app/proxyman"
	_ "v2ray.com/core/app/proxyman/inbound"
	_ "v2ray.com/core/app/proxyman/outbound"

	"v2ray.com/core/common/net"
	"v2ray.com/core/common/protocol"
	"v2ray.com/core/common/serial"

	"v2ray.com/core/proxy/dokodemo"
	"v2ray.com/core/proxy/freedom"

	"v2ray.com/core/transport/internet"
	"v2ray.com/core/transport/internet/quic"
	"v2ray.com/core/transport/internet/tls"
	"v2ray.com/core/transport/internet/websocket"
)

var (
	vpn        = flag.Bool("V", false, "Run in VPN mode.")
	fastOpen   = flag.Bool("fast-open", false, "Enable TCP fast open.")
	localAddr  = flag.String("localAddr", "127.0.0.1", "local address to listen on.")
	localPort  = flag.String("localPort", "1984", "local port to listen on.")
	remoteAddr = flag.String("remoteAddr", "127.0.0.1", "remote address to forward.")
	remotePort = flag.String("remotePort", "1080", "remote port to forward.")
	path       = flag.String("path", "/", "URL path for websocket.")
	host       = flag.String("host", "cloudfront.com", "Host header for websocket.")
	tlsEnabled = flag.Bool("tls", false, "Enable TLS.")
	mode       = flag.String("mode", "websocket", "Transport mode: websocket/quic.")
	server     = flag.Bool("server", false, "Run in server mode")
)

func generateConfig() (*core.Config, error) {
	lport, err := net.PortFromString(*localPort)
	if err != nil {
		return nil, newError("invalid localPort:", *localPort).Base(err)
	}
	rport, err := strconv.ParseUint(*remotePort, 10, 32)
	if err != nil {
		return nil, newError("invalid remotePort:", *remotePort).Base(err)
	}

	var transportSettings proto.Message
	switch *mode{
	case "websocket":
		transportSettings = &websocket.Config{
			Path: *path,
			Header: []*websocket.Header{
				{Key: "Host", Value: *host},
			},
		}
	case "quic":
		transportSettings = &quic.Config{
			Security: &protocol.SecurityConfig{Type: protocol.SecurityType_NONE},
		}
		*tlsEnabled = true
	default:
		return nil, newError("unsupported mode:", *mode)
	}

	apps := []*serial.TypedMessage{
		serial.ToTypedMessage(&dispatcher.Config{}),
		serial.ToTypedMessage(&proxyman.InboundConfig{}),
		serial.ToTypedMessage(&proxyman.OutboundConfig{}),
		serial.ToTypedMessage(&vLog.Config{}),
	}
	if *server {
		return &core.Config{
			Inbound: []*core.InboundHandlerConfig{{
				ReceiverSettings: serial.ToTypedMessage(&proxyman.ReceiverConfig{
					PortRange: net.SinglePortRange(lport),
					Listen:	net.NewIPOrDomain(net.ParseAddress(*localAddr)),
					StreamSettings: &internet.StreamConfig{
						ProtocolName: *mode,
						TransportSettings: []*internet.TransportConfig{{
							ProtocolName: *mode,
							Settings: serial.ToTypedMessage(transportSettings),
						}},
					},
				}),
				ProxySettings: serial.ToTypedMessage(&dokodemo.Config{
					// This address is required when mux is used on client.
					// dokodemo is not aware of mux connections by itself.
					// Change this value to net.LocalHostIP if mux is disabled.
					Address: net.NewIPOrDomain(net.ParseAddress("v1.mux.cool")),
					Networks: []net.Network{net.Network_TCP},
				}),
			}},
			Outbound: []*core.OutboundHandlerConfig{{
				ProxySettings: serial.ToTypedMessage(&freedom.Config{
					DestinationOverride: &freedom.DestinationOverride{
						Server: &protocol.ServerEndpoint{
							Address: net.NewIPOrDomain(net.ParseAddress(*remoteAddr)),
							Port: uint32(rport),
						},
					},
				}),
			}},
			App: apps,
		}, nil
	} else {
		var securityType string
		var securitySettings []*serial.TypedMessage
		if *tlsEnabled {
			securityType = serial.GetMessageType(&tls.Config{})
			securitySettings = []*serial.TypedMessage{serial.ToTypedMessage(&tls.Config{
				ServerName: *host,
			})}
		}

		return &core.Config{
			Inbound: []*core.InboundHandlerConfig{{
				ReceiverSettings: serial.ToTypedMessage(&proxyman.ReceiverConfig{
					PortRange: net.SinglePortRange(lport),
					Listen:	net.NewIPOrDomain(net.ParseAddress(*localAddr)),
				}),
				ProxySettings: serial.ToTypedMessage(&dokodemo.Config{
					Address: net.NewIPOrDomain(net.LocalHostIP),
					Networks: []net.Network{net.Network_TCP},
				}),
			}},
			Outbound: []*core.OutboundHandlerConfig{{
				SenderSettings: serial.ToTypedMessage(&proxyman.SenderConfig{
					StreamSettings: &internet.StreamConfig{
						ProtocolName: *mode,
						TransportSettings: []*internet.TransportConfig{{
							ProtocolName: *mode,
							Settings: serial.ToTypedMessage(transportSettings),
						}},
						SecurityType: securityType,
						SecuritySettings: securitySettings,
					},
					MultiplexSettings: &proxyman.MultiplexingConfig{
						Enabled: true,
						Concurrency: 8,
					},
				}),
				ProxySettings: serial.ToTypedMessage(&freedom.Config{
					DestinationOverride: &freedom.DestinationOverride{
						Server: &protocol.ServerEndpoint{
							Address: net.NewIPOrDomain(net.ParseAddress(*remoteAddr)),
							Port: uint32(rport),
						},
					},
				}),
			}},
			App: apps,
		}, nil
	}
}

func startV2Ray() (core.Server, error) {

	if *vpn {
		registerControlFunc()
	}

	opts, err := parseEnv()

	if err == nil {
		if c, b := opts.Get("mode"); b {
			*mode = c
		}
		if _, b := opts.Get("tls"); b {
			*tlsEnabled = true
		}
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
			if *server {
				*remoteAddr = c
			} else {
				*localAddr = c
			}
		}
		if c, b := opts.Get("localPort"); b {
			if *server {
				*remotePort = c
			} else {
				*localPort = c
			}
		}
		if c, b := opts.Get("remoteAddr"); b {
			if *server {
				*localAddr = c
			} else {
				*remoteAddr = c
			}
		}
		if c, b := opts.Get("remotePort"); b {
			if *server {
				*localPort = c
			} else {
				*remotePort = c
			}
		}
	}

	config, err := generateConfig()
	if err != nil {
		return nil, newError("failed to parse config").Base(err)
	}
	instance, err := core.New(config)
	if err != nil {
		return nil, newError("failed to create v2ray instance").Base(err)
	}
	if err := instance.Start(); err != nil {
		return nil, newError("failed to start server").Base(err)
	}
	return instance, nil
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

	{
		osSignals := make(chan os.Signal, 1)
		signal.Notify(osSignals, os.Interrupt, os.Kill, syscall.SIGTERM)
		<-osSignals
	}
}
