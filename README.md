## Yet another SIP003 plugin for shadowsocks, based on [v2ray-core](https://github.com/v2fly/v2ray-core)

[![CircleCI](https://circleci.com/gh/shadowsocks/v2ray-plugin.svg?style=shield)](https://circleci.com/gh/shadowsocks/v2ray-plugin)
[![Releases](https://img.shields.io/github/downloads/shadowsocks/v2ray-plugin/total.svg)](https://github.com/shadowsocks/v2ray-plugin/releases)
[![Language: Go](https://img.shields.io/badge/go-1.22+-blue.svg)](https://github.com/shadowsocks/v2ray-plugin/search?l=go)
[![Go Report Card](https://goreportcard.com/badge/github.com/shadowsocks/v2ray-plugin)](https://goreportcard.com/report/github.com/shadowsocks/v2ray-plugin)
[![License](https://img.shields.io/github/license/shadowsocks/v2ray-plugin.svg)](LICENSE)

## Build

* `go build`
* This repository vendors its dependencies under `vendor/` (including a local patch that lets uTLS honor `insecure`). Go uses `vendor/` automatically for `go >= 1.14`, so no extra flag is required. If you change dependencies, run `go mod vendor` again and re-apply the patch in `vendor/github.com/v2fly/v2ray-core/v5/transport/internet/tls/utls/utls.go`.
* Alternatively, you can grab the latest nightly from Circle CI by logging into Circle CI or adding `#artifacts` at the end of URL like such: https://circleci.com/gh/shadowsocks/v2ray-plugin/20#artifacts

## Command Line Options

```
-server          Run in server mode
-fast-open       Enable TCP fast open
-localAddr       Local address to listen on (default: 127.0.0.1)
-localPort       Local port to listen on (default: 1984)
-remoteAddr      Remote address to forward (default: 127.0.0.1)
-remotePort      Remote port to forward (default: 1080)
-path            URL path for websocket (default: /)
-host            Hostname for server (default: cloudfront.com)
-tls             Enable TLS
-cert            Path to TLS certificate file (default: ~/.acme.sh/{host}/fullchain.cer)
-certRaw         Raw TLS certificate content (PEM format, intended for Android)
-key             (server) Path to TLS key file (default: ~/.acme.sh/{host}/{host}.key)
-mode            Transport mode: websocket, quic (default: websocket)
-mux             Concurrent multiplexed connections, websocket client mode only (default: 1)
-loglevel        Log level for v2ray: debug, info, warning (default), error, none
-insecure        Skip TLS certificate verification
-fingerprint     uTLS TLS ClientHello fingerprint to imitate a real browser (client only)
-fwmark          Set SO_MARK option for outbound sockets (Linux only)
-version         Show current version of v2ray-plugin
-V               Run in VPN mode (Android only)
```

## Usage

See command line args for advanced usages.

### Shadowsocks over websocket (HTTP)

Warning: HTTP only provides a moderate (but lightweight) traffic obfuscation. Cautious users should refrain from using this mode.

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
ss-server -c config.json -p 443 --plugin v2ray-plugin --plugin-opts "server;tls;host=mydomain.me"
```

On your client

```sh
ss-local -c config.json -p 443 --plugin v2ray-plugin --plugin-opts "tls;host=mydomain.me"
```

### Shadowsocks over quic

On your server

```sh
ss-server -c config.json -p 443 --plugin v2ray-plugin --plugin-opts "server;mode=quic;host=mydomain.me"
```

On your client

```sh
ss-local -c config.json -p 443 --plugin v2ray-plugin --plugin-opts "mode=quic;host=mydomain.me"
```

### TLS fingerprint (uTLS)

By default the client performs a plain Go `crypto/tls` handshake, whose ClientHello (JA3/JA4) fingerprint is easily distinguished from real browsers. Adding `fingerprint` makes the client imitate a chosen browser's TLS handshake via [uTLS](https://github.com/refraction-networking/utls).

This option only takes effect on the **client** side (a TLS ClientHello is only sent by the connecting party); it is ignored on the server.

On your client

```sh
ss-local -c config.json -p 443 --plugin v2ray-plugin --plugin-opts "tls;host=mydomain.me;fingerprint=chrome_auto"
```

Or from the command line:

```
v2ray-plugin -client -tls -host mydomain.me -fingerprint chrome_auto
```

> The server side needs no change: it just accepts a normal TLS connection. The fingerprint only affects how the client's handshake looks to on-path observers.

Available fingerprint values:

| Family | Values |
|--------|--------|
| Chrome | `chrome_auto`, `chrome_58`, `chrome_62`, `chrome_70`, `chrome_72`, `chrome_83`, `chrome_87`, `chrome_96`, `chrome_100`, `chrome_102` |
| Firefox | `firefox_auto`, `firefox_55`, `firefox_56`, `firefox_63`, `firefox_65`, `firefox_99`, `firefox_102`, `firefox_105` |
| Safari | `safari_auto`, `safari_16_0` |
| iOS | `ios_auto`, `ios_11_1`, `ios_12_1`, `ios_13`, `ios_14` |
| Edge | `edge_auto`, `edge_85`, `edge_106` |
| Android | `android_11_okhttp` |
| 360 | `360_auto`, `360_7_5`, `360_11_0` |
| QQ | `qq_auto`, `qq_11_1` |
| Randomized | `randomized`, `randomizedalpn`, `randomizednoalpn` |

The `*_auto` variants track the latest preset bundled with the underlying uTLS version and are recommended. Leaving `fingerprint` empty (the default) keeps the native Go TLS behavior.

Combining with `insecure`: upstream v2ray-core silently drops `insecure` when a uTLS fingerprint is active, so a self-signed or expired server certificate fails the handshake. This fork patches the vendored uTLS engine to honor `InsecureSkipVerify`, so `fingerprint` and `insecure` work together:

```
v2ray-plugin -client -tls -host mydomain.me -fingerprint chrome_auto -insecure
```

Prefer a valid certificate when possible; `insecure` disables verification and should only be used for self-signed setups you trust.

### Issue a cert for TLS and QUIC

`v2ray-plugin` will look for TLS certificates signed by [acme.sh](https://github.com/acmesh-official/acme.sh) by default.
Here's some sample commands for issuing a certificate using CloudFlare.
You can find commands for issuing certificates for other DNS providers at acme.sh.

```sh
curl https://get.acme.sh | sh
~/.acme.sh/acme.sh --issue --dns dns_cf -d mydomain.me
```

Alternatively, you can specify path to your certificates using option `cert` and `key`.

### Use `certRaw` to pass certificate

Instead of using `cert` to pass the certificate file, `certRaw` could be used to pass in PEM format certificate, that is the content between `-----BEGIN CERTIFICATE-----` and `-----END CERTIFICATE-----` without the line breaks.

### Other options

* Use `insecure` to skip TLS certificate verification.
* Use `fingerprint` to make the client's TLS handshake mimic a real browser via uTLS (client only, see [TLS fingerprint](#tls-fingerprint-utls)).
* Use `fastOpen` to enable TCP fast open.
* Use `fwmark` to set SO_MARK option for outbound sockets (Linux only).
* Use `loglevel` to control log verbosity. Available values: `debug`, `info`, `warning`, `error`, `none`.
