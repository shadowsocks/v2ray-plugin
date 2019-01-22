# Yet another SIP003 plugin for shadowsocks, based on v2ray

[![CircleCI](https://circleci.com/gh/shadowsocks/v2ray-plugin.svg?style=shield)](https://circleci.com/gh/shadowsocks/v2ray-plugin)
[![Releases](https://img.shields.io/github/downloads/shadowsocks/v2ray-plugin/total.svg)](https://github.com/shadowsocks/v2ray-plugin/releases)
[![Language: Go](https://img.shields.io/badge/go-1.11+-blue.svg)](https://github.com/shadowsocks/v2ray-plugin/search?l=go)
[![Go Report Card](https://goreportcard.com/badge/github.com/shadowsocks/v2ray-plugin)](https://goreportcard.com/report/github.com/shadowsocks/v2ray-plugin)
[![License](https://img.shields.io/github/license/shadowsocks/v2ray-plugin.svg)](LICENSE)

## Build

```sh
go build
```

## Commands

```sh
➜  ~ v2ray-plugin --help
Usage of v2ray-plugin:
  -V    Run in VPN mode.
  -cert string
        Path to TLS certificate file. Overrides certRaw. Default: ~/.acme.sh/{host}/fullchain.cer
  -certRaw string
        Raw TLS certificate content. Intended only for Android.
  -fast-open
        Enable TCP fast open.
  -host string
        Hostname for server. (default "cloudfront.com")
  -key string
        (server) Path to TLS key file. Default: ~/.acme.sh/{host}/{host}.key
  -localAddr string
        local address to listen on. (default "127.0.0.1")
  -localPort string
        local port to listen on. (default "1984")
  -loglevel string
        loglevel for v2ray: debug, info, warning (default), error, none.
  -mode string
        Transport mode: websocket, quic (enforced tls). (default "websocket")
  -mux int
        Concurrent multiplexed connections (websocket client mode only). (default 1)
  -path string
        URL path for websocket. (default "/")
  -remoteAddr string
        remote address to forward. (default "127.0.0.1")
  -remotePort string
        remote port to forward. (default "1080")
  -server
        Run in server mode
  -tls
        Enable TLS.
```

### Shadowsocks over websocket (HTTP)

On your server

```sh
ss-server -c config.json -p 80 --plugin v2ray-plugin --plugin-opts "server"
```

On your client

```sh
ss-local -c config.json -p 80 --plugin v2ray-plugin
```

### Shadowsocks over websocket (HTTPS)

On your server

```sh
ss-server -c config.json -p 443 --plugin v2ray-plugin --plugin-opts "server;tls"
```

On your client

```sh
ss-local -c config.json -p 443 --plugin v2ray-plugin --plugin-opts "tls"
```

### Shadowsocks over quic

On your server

```sh
ss-server -c config.json -p 443 --plugin v2ray-plugin --plugin-opts "server;mode=quic"
```

On your client

```sh
ss-local -c config.json -p 443 --plugin v2ray-plugin --plugin-opts "mode=quic"
```
