# v2ray-plugin

This glossary defines the terms used when the plugin transports Shadowsocks data.

## Language

**Hysteria2 transport mode**:
A stream transport that carries Shadowsocks data between a client plugin and a server plugin over Hysteria2.
_Avoid_: Hysteria2 proxy node, official Hysteria2 proxy compatibility mode

**Client plugin**:
The plugin role on the Shadowsocks client side that establishes a transport connection to the server plugin.

**Server plugin**:
The plugin role on the Shadowsocks server side that accepts transport connections from client plugins.

**Hysteria2 transport password**:
The shared credential used to authenticate the Hysteria2 transport connection, separate from the Shadowsocks password.
_Avoid_: Shadowsocks password
