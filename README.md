## Yet another SIP003 plugin for shadowsocks, based on [v2ray](https://github.com/v2fly/v2ray-core)

[![Releases](https://img.shields.io/github/downloads/shadowsocks/v2ray-plugin/total.svg)](https://github.com/shadowsocks/v2ray-plugin/releases)
[![Language: Go](https://img.shields.io/badge/go-1.26.0+-blue.svg)](https://github.com/shadowsocks/v2ray-plugin/search?l=go)
[![License](https://img.shields.io/github/license/shadowsocks/v2ray-plugin.svg)](LICENSE)

## Build

Requires Go 1.26.0 or later. Release builds use [Task](https://taskfile.dev/).

See [RELEASING.md](docs/RELEASING.md) for instructions on preparing and
publishing a release.

* `go build`
* `go test ./...` runs integration tests using local TCP and UDP sockets.

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

### Shadowsocks over Hysteria2 transport

Hysteria2 transport mode carries Shadowsocks TCP data between two instances of
this plugin. Both endpoints must use `mode=hysteria2`; ordinary Hysteria2 proxy
nodes are not compatible with this transport-only mode.

On your server

```sh
ss-server -c config.json -p 443 --plugin v2ray-plugin --plugin-opts "server;mode=hysteria2;host=mydomain.me;password=transport-secret"
```

On your client

```sh
ss-local -c config.json -p 443 --plugin v2ray-plugin --plugin-opts "mode=hysteria2;host=mydomain.me;password=transport-secret"
```

The `password` option authenticates the Hysteria2 transport and is separate from
the Shadowsocks password in `config.json`. It is optional: omit it on both
endpoints to use no transport password authentication. An empty server password
accepts any client transport password; a nonempty server password requires a
matching client password.

Hysteria2 automatically enables TLS 1.3 and uses the existing `host`, `cert`,
`certRaw`, and `key` options and default certificate paths. Clients verify the
server certificate and hostname. For a private certificate authority, pass its
certificate using the client `cert` option. No certificate verification bypass
option is provided.

Allow inbound **UDP** on the server's transport port (443 in this example).
The local plugin connection still uses TCP; this mode does not forward
Shadowsocks UDP traffic or expose the Hysteria2 UDP extension. The WebSocket
`mux` and `path` options are ignored. Congestion control uses upstream defaults;
there are no bandwidth or congestion algorithm options.

The same options are available as command-line flags, for example
`-mode=hysteria2 -password=transport-secret -host=mydomain.me`.
See the [upstream Hysteria2 transport documentation](https://www.v2fly.org/config/transport/hy2.html)
for the distinction between transport and proxy modes.

### Issue a cert for TLS, QUIC, and Hysteria2

`v2ray-plugin` will look for TLS certificates signed by [acme.sh](https://github.com/acmesh-official/acme.sh) by default.
When the server has no `cert`, `certRaw`, or `key` option, it first tries
`~/.acme.sh/{host}/fullchain.cer` and `~/.acme.sh/{host}/{host}.key`.
If either file is missing, it tries both files in `~/.acme.sh/{host}_ecc/`.
The ECC key filename is still `{host}.key`. Both files must come from the same
directory. Other read errors and invalid certificate contents do not trigger
fallback. If any of these options is specified, omitted paths keep their
original defaults under `~/.acme.sh/{host}/`.

Here's some sample commands for issuing a certificate using CloudFlare.
You can find commands for issuing certificates for other DNS providers at acme.sh.

```sh
curl https://get.acme.sh | sh
~/.acme.sh/acme.sh --issue --dns dns_cf -d mydomain.me
```

Alternatively, you can specify path to your certificates using option `cert` and `key`.

### Use `certRaw` to pass certificate

Instead of using `cert` to pass the certificate file, `certRaw` could be used to pass in PEM format certificate, that is the content between `-----BEGIN CERTIFICATE-----` and `-----END CERTIFICATE-----` without the line breaks.
