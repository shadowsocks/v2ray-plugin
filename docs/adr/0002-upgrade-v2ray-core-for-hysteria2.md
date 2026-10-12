---
status: accepted
---

# Upgrade V2Ray core for Hysteria2 integration

Upgrade V2Ray core from v5.22.0 to the verified stable release v5.53.0 for Hysteria2 integration. The old release requires the main module to mirror a Hysteria dependency replacement targeting a separate fork; the selected release directly depends on the V2Fly Hysteria module. We accept a broader dependency update and a minimum Go version of 1.25.5 to use that upstream dependency arrangement instead of retaining the older fork replacement.

Validate WebSocket and QUIC alongside Hysteria2 because the core upgrade affects existing transports. The upstream module also declares `toolchain go1.26.1`; the plugin's build and CI configuration must be checked against the selected dependency rather than assuming its existing Go requirements remain sufficient.

Reference: [V2Ray core v5.53.0 go.mod](https://github.com/v2fly/v2ray-core/blob/v5.53.0/go.mod).
