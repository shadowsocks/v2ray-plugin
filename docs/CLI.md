# Command-Line Reference

`v2ray-plugin` is a SIP003 transport plugin for Shadowsocks. It carries TCP
streams between a Shadowsocks client and server over WebSocket, QUIC, or
Hysteria2. It does not provide a SOCKS proxy or Shadowsocks encryption by
itself. QUIC and Hysteria2 use UDP for the outer transport, but this plugin
still carries Shadowsocks TCP traffic only.

When a Shadowsocks implementation starts the plugin, configure it with
`--plugin` and `--plugin-opts`. The parent passes endpoint information through
the SIP003 environment variables. You can also run the plugin directly with
its command-line flags.

## Command-line flags

Run `v2ray-plugin -h` or `v2ray-plugin -help` to print the built-in help.
String and numeric flags accept either `-name=value` or `-name value`. Boolean
flags can be enabled by presence, such as `-tls` or `-server`, or set
explicitly with `-tls=false`.

In direct client mode, `localAddr:localPort` is the plugin's local listener and
`remoteAddr:remotePort` is the remote plugin service. With `-server`, the local
endpoint is the plugin server listener and the remote endpoint is the local
Shadowsocks server to which it forwards traffic.

| Flag | Default | Description |
| --- | --- | --- |
| `-V` | `false` | Enable Android VPN socket protection. This has no effect in non-Android builds. |
| `-fast-open` | `false` | Enable TCP Fast Open on the transport sockets. The OS and network must support it. |
| `-localAddr` | `127.0.0.1` | Address for the plugin's local listener. In server mode, it accepts multiple pipe-separated listen addresses. |
| `-localPort` | `1984` | Port for the plugin's local listener. In server mode, this is the plugin server port. |
| `-remoteAddr` | `127.0.0.1` | Forwarding destination. In client mode, this is the remote plugin service; in server mode, it is the local Shadowsocks service. |
| `-remotePort` | `1080` | Port for the forwarding destination. |
| `-server` | `false` | Run the server role. The default role is client. |
| `-mode` | `websocket` | Transport: `websocket`, `quic`, or `hysteria2`. The name `hy2` is not an alias. |
| `-tls` | `false` | Enable TLS for WebSocket. QUIC and Hysteria2 enable TLS automatically. |
| `-host` | `cloudfront.com` | WebSocket `Host` header and TLS server name. Set this to the hostname used by the server certificate. |
| `-path` | `/` | WebSocket URL path. The client and server paths must match. Ignored by QUIC and Hysteria2. |
| `-cert` | empty | Certificate file. On a server, this is the TLS certificate; on a client, it is a custom CA certificate. If both `-cert` and `-certRaw` are set, `-cert` takes precedence. |
| `-certRaw` | empty | Raw Base64 body of the server certificate or client CA, without PEM markers or line breaks. Intended for Android integrations. |
| `-key` | empty | Server-side TLS private key file. Not used by the client. |
| `-password` | empty | Optional Hysteria2 transport password. It is separate from the Shadowsocks password and is ignored by other modes. |
| `-mux` | `1` | Number of concurrent multiplexed WebSocket connections on the client. Set to `0` to disable WebSocket multiplexing. Ignored by QUIC and Hysteria2. |
| `-fwmark` | `0` | Set the outbound socket `SO_MARK` value. `0` disables it; nonzero values must fit in an unsigned 32-bit integer. Platform and kernel support are required. |
| `-loglevel` | `warning` | V2Ray log level: `debug`, `info`, `warning`, `error`, or `none`. An empty or unrecognized value uses `warning`. |
| `-disableAccessLog` | `false` | Disable V2Ray access logs. Access logging remains enabled by default. `-loglevel=none` still disables all V2Ray logs. |
| `-version` | `false` | Print the plugin version and Go runtime version, then exit. |

The table lists every application flag. The Go flag package also provides
`-h` and `-help` for built-in help. `-mux` and `-fwmark` accept unsigned
integers up to `4294967295`.

## TLS certificates

Without `-cert` or `-certRaw`, a TLS client uses the system certificate roots.
Set `-cert` on the client to trust a private CA, or use `-certRaw` with that
certificate's Base64 body. The client verifies the server certificate against
`-host`.

On a TLS server, if `-cert`, `-certRaw`, and `-key` are all unset, the plugin
looks for a complete certificate and key pair in these directories, in order:

1. `~/.acme.sh/{host}/fullchain.cer` and `~/.acme.sh/{host}/{host}.key`
2. `~/.acme.sh/{host}_ecc/fullchain.cer` and `~/.acme.sh/{host}_ecc/{host}.key`

If any certificate or key option is set, this complete-pair fallback is not
used. An omitted certificate or key path then defaults to the regular
`~/.acme.sh/{host}/` directory. For example, setting `-cert` without `-key`
still makes the plugin look for the key at `~/.acme.sh/{host}/{host}.key`.

`-certRaw` is for integrations that can pass a certificate's Base64 body but
cannot pass a file path. Do not include `-----BEGIN CERTIFICATE-----` or
`-----END CERTIFICATE-----` in the value.

## SIP003 environment and plugin options

The [SIP003 plugin specification](https://shadowsocks5.github.io/en/spec/Plugin)
defines four endpoint variables and one optional options variable:

| Environment variable | Meaning |
| --- | --- |
| `SS_LOCAL_HOST`, `SS_LOCAL_PORT` | Local Shadowsocks or plugin service endpoint. |
| `SS_REMOTE_HOST`, `SS_REMOTE_PORT` | Remote plugin service endpoint. |
| `SS_PLUGIN_OPTIONS` | Optional semicolon-separated plugin options. |

The endpoint mapping depends on the role:

| Role | `SS_LOCAL_*` | `SS_REMOTE_*` |
| --- | --- | --- |
| Client (default) | Local listener that receives streams from the Shadowsocks client. | Remote plugin server to connect to. |
| Server (`server`) | Local Shadowsocks server to forward streams to. | Address and port where the plugin server listens. |

All four endpoint variables must be nonempty for this implementation to read
SIP003 settings. If any is missing or empty, it ignores the SIP003 environment,
including `SS_PLUGIN_OPTIONS`, and uses the command-line values and defaults.

### Supported `SS_PLUGIN_OPTIONS` keys

Names are case-sensitive. The endpoint override options follow the SIP003
`SS_LOCAL_*` and `SS_REMOTE_*` meaning in the role table above; their meaning
therefore changes with the `server` option. The command-line flags with the
same names use the direct CLI meanings described earlier.

| Option | Value | Description |
| --- | --- | --- |
| `server` | presence | Enable server role. Omit it for the client role. |
| `mode` | `websocket`, `quic`, `hysteria2` | Select the transport. |
| `localAddr` | address | Override the `SS_LOCAL_HOST` endpoint. |
| `localPort` | port | Override the `SS_LOCAL_PORT` endpoint. |
| `remoteAddr` | address | Override the `SS_REMOTE_HOST` endpoint. |
| `remotePort` | port | Override the `SS_REMOTE_PORT` endpoint. |
| `tls` | presence | Enable TLS. QUIC and Hysteria2 enable it automatically. |
| `host` | hostname | WebSocket `Host` header and TLS server name. |
| `path` | URL path | WebSocket path; ignored by QUIC and Hysteria2. |
| `cert` | file path | Server certificate or client CA certificate. Overrides `certRaw`. |
| `certRaw` | Base64 body | Raw certificate body for integrations such as Android. |
| `key` | file path | Server-side TLS private key. |
| `mux` | unsigned integer | WebSocket client multiplexing concurrency; `0` disables it. |
| `password` | string | Optional Hysteria2 transport password. |
| `fastOpen` | presence | Enable TCP Fast Open. The option name is camelCase. |
| `fwmark` | unsigned integer | Set the outbound socket mark; `0` disables it. |
| `loglevel` | `debug`, `info`, `warning`, `error`, `none` | Set the V2Ray log level. |
| `disableAccessLog` | presence only | Disable V2Ray access logs. Do not add `=value`; values are rejected. |
| `__android_vpn` | presence | Internal Android VPN socket-protection option. Do not use in normal desktop configurations. |

There is no SIP003 option for `-version`. The Android `__android_vpn` option
corresponds to the VPN integration enabled by `-V`.

### Option syntax and precedence

Options use `key=value` pairs separated by semicolons. Boolean options can be
written as bare keys:

```text
server;tls;mode=websocket;host=ws.example.com;path=/tunnel;mux=8
```

Escape semicolons, equals signs, and backslashes in keys or values with a
backslash. Quote the complete option string for the shell:

```sh
--plugin-opts 'path=/ws\;v2;password=secret\=part'
```

The parser removes the escape backslashes, so the values above become
`/ws;v2` and `secret=part`. For a literal backslash, use `\\` in the option
string. A bare boolean key enables the option. Boolean values are based on
presence, so `tls=false` still enables TLS; omit `tls` to leave it disabled.
`disableAccessLog` is a presence-only opt-out: use the bare key, and do not
provide a value.

For duplicate keys, the first value is used. Unknown keys are ignored. Direct
command-line flags are parsed first; complete SIP003 endpoint variables then
override matching endpoints, and recognized `SS_PLUGIN_OPTIONS` entries
override matching values. `disableAccessLog` is an opt-out: if the CLI flag is
true or the SIP003 key is present, access logs are disabled. Either source can
request disabling; neither can re-enable logs disabled by the other. If the
key is absent and the CLI flag is false, access logs remain enabled.

With all SIP003 endpoint variables present, malformed `SS_PLUGIN_OPTIONS`
causes startup to fail with a configuration error.

## Transport modes

### WebSocket

WebSocket is the default and uses TCP. TLS is optional. Without TLS, the
WebSocket connection is plain HTTP; Shadowsocks still encrypts its payload,
but the transport does not use TLS. `host`, `path`, and client-side `mux`
apply to this mode.

### QUIC

Set `mode=quic`. TLS is enabled automatically, and the transport uses UDP.
Allow inbound UDP on the server port. `path` and `mux` are ignored.

### Hysteria2 transport

Set `mode=hysteria2` on both endpoints. TLS is enabled automatically, and the
transport uses UDP. The optional `password` authenticates this transport; it is
not the Shadowsocks password. If the server password is empty, transport
password authentication is disabled. If it is nonempty, clients must use the
same value. This mode carries Shadowsocks TCP data; it does not add Shadowsocks
UDP forwarding or make the plugin compatible with ordinary Hysteria2 proxy
nodes. `path` and `mux` are ignored.

## Common configurations

The examples use the Shadowsocks CLI convention shown here. Replace the
configuration files, hostnames, ports, and executable paths for your
Shadowsocks implementation. Both endpoints must use the same transport mode;
for WebSocket they must also use the same `host` and `path`.

### Plain WebSocket

This uses WebSocket without TLS. Add `tls` and configure certificates for a
TLS-protected connection.

Server:

```sh
ss-server -c server.json -p 80 \
  --plugin v2ray-plugin \
  --plugin-opts 'server;host=ws.example.com;path=/tunnel'
```

Client:

```sh
ss-local -c client.json -p 80 \
  --plugin v2ray-plugin \
  --plugin-opts 'host=ws.example.com;path=/tunnel'
```

### WebSocket with TLS

The server can use the automatic acme.sh certificate lookup described above:

```sh
# Server
ss-server -c server.json -p 443 \
  --plugin v2ray-plugin \
  --plugin-opts 'server;tls;host=ws.example.com;path=/tunnel'

# Client
ss-local -c client.json -p 443 \
  --plugin v2ray-plugin \
  --plugin-opts 'tls;host=ws.example.com;path=/tunnel'
```

For custom files, add `cert=/etc/ssl/fullchain.pem;key=/etc/ssl/private.key`
to the server options. For a private CA, add `cert=/etc/ssl/private-ca.pem` to
the client options. Do not give the client the server's private key.

### WebSocket with multiplexing

Set `mux` on the client to use the requested concurrency. The server does not
need a `mux` option:

```sh
ss-local -c client.json -p 443 \
  --plugin v2ray-plugin \
  --plugin-opts 'tls;host=ws.example.com;path=/tunnel;mux=8'
```

Use `mux=0` to disable WebSocket multiplexing. The default is `mux=1`.

### QUIC

QUIC enables TLS automatically. Open the server port for UDP traffic:

```sh
# Server
ss-server -c server.json -p 443 \
  --plugin v2ray-plugin \
  --plugin-opts 'server;mode=quic;host=quic.example.com'

# Client
ss-local -c client.json -p 443 \
  --plugin v2ray-plugin \
  --plugin-opts 'mode=quic;host=quic.example.com'
```

### Hysteria2 transport with a password

Both plugins must use `mode=hysteria2` and the same transport password. Open
the server port for UDP traffic:

```sh
# Server
ss-server -c server.json -p 443 \
  --plugin v2ray-plugin \
  --plugin-opts 'server;mode=hysteria2;host=hy2.example.com;password=transport-secret'

# Client
ss-local -c client.json -p 443 \
  --plugin v2ray-plugin \
  --plugin-opts 'mode=hysteria2;host=hy2.example.com;password=transport-secret'
```

Omit `password` on both sides to disable Hysteria2 transport password
authentication. The Shadowsocks password remains configured separately in the
Shadowsocks client and server.

## Direct invocation

When another program provides the matching TCP endpoints, run the plugin
without `--plugin-opts` and use its flags directly. Unset inherited
`SS_LOCAL_*`, `SS_REMOTE_*`, and `SS_PLUGIN_OPTIONS` variables so they do not
override the flags. For example, the server role listens for WebSocket TLS on
port 443 and forwards streams to a local Shadowsocks server on port 8388:

```sh
./v2ray-plugin \
  -server \
  -localAddr 0.0.0.0 -localPort 443 \
  -remoteAddr 127.0.0.1 -remotePort 8388 \
  -mode websocket -tls -host ws.example.com -path /tunnel \
  -cert /etc/ssl/fullchain.pem -key /etc/ssl/private.key
```

A client-side instance can listen locally and connect to that plugin server:

```sh
./v2ray-plugin \
  -localAddr 127.0.0.1 -localPort 1984 \
  -remoteAddr ws.example.com -remotePort 443 \
  -mode websocket -tls -host ws.example.com -path /tunnel
```

The Shadowsocks client must connect to the client instance's local port, and
the server instance must forward to a local Shadowsocks server. The plugin
does not replace either Shadowsocks process.
