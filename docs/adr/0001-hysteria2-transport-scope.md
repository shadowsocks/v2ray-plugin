---
status: accepted
---

# Limit Hysteria2 support to Shadowsocks plugin transport

This project transports Shadowsocks data through a plugin. Hysteria2 support keeps that boundary and covers both client and server roles. Transport integration preserves the plugin's purpose without introducing the destination handling and proxy semantics of a standalone Hysteria2 proxy.

Both endpoints must use a matching plugin transport mode; interoperability with ordinary official Hysteria2 proxy nodes is outside this scope. The plugin continues to forward TCP only. The transport's use of UDP does not add Shadowsocks UDP forwarding, and the Hysteria2 UDP extension is not exposed.

Hysteria2 transport passwords are optional and separate from Shadowsocks passwords. An empty server password disables transport password authentication, following upstream behavior. Hysteria2 automatically enables TLS and reuses the existing host, certificate, and key options and certificate lookup paths. Clients retain certificate verification without a new verification bypass option. The initial implementation uses upstream default congestion control and exposes no bandwidth or congestion algorithm options.

The public mode name is `hysteria2`, without a `hy2` alias. Both command-line flags and SIP003 plugin options accept the transport password as `password`. Hysteria2 ignores the WebSocket-specific `mux` and `path` options, matching the existing QUIC behavior, and does not add V2Ray Mux.

References: [V2Fly Hysteria2 transport and proxy split](https://www.v2fly.org/config/transport/hy2.html), [SIP003 TCP forwarding contract](https://shadowsocks.org/doc/sip003.html).
