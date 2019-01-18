# Yet another SIP003 plugin for shadowsocks, based on v2ray

[![CircleCI](https://circleci.com/gh/shadowsocks/v2ray-plugin.svg?style=svg)](https://circleci.com/gh/shadowsocks/v2ray-plugin)
[![Releases](https://img.shields.io/github/downloads/shadowsocks/v2ray-plugin/total.svg)](https://github.com/shadowsocks/v2ray-plugin/releases)
[![Language: Go](https://img.shields.io/github/languages/top/shadowsocks/v2ray-plugin.svg)](https://github.com/shadowsocks/v2ray-plugin/search?l=go)
[![Codacy Badge](https://api.codacy.com/project/badge/Grade/5551969afc234e449a91cd2ea491dce5)](https://www.codacy.com/app/shadowsocks/v2ray-plugin?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=shadowsocks/v2ray-plugin&amp;utm_campaign=Badge_Grade)
[![License](https://img.shields.io/github/license/shadowsocks/v2ray-plugin.svg)](LICENSE)

## Requirements
### Shadowsocks and Go Language (1.11+)

## Build

```sh
git clone https://github.com/shadowsocks/v2ray-plugin/
cd v2ray-plugin
git submodule update --init --recursive
go build
```

## Usage

See command line args for advanced usages.

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
