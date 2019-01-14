# Yet another SIP003 plugin for shadowsocks, based on v2ray

## Build

```
go get
go build
```

## Usage

### Shadowsocks over websocket (HTTP)

On your server

```
ss-server -c config.json -p 80 --plugin v2ray-plugin --plugin-opts "server"
```

On your client

```
ss-local -c config.json -p 80 --plugin v2ray-plugin
```

### Shadowsocks over websocket (HTTPS)

On your server

```
ss-server -c config.json -p 443 --plugin v2ray-plugin --plugin-opts "server;tls"
```

On your client

```
ss-local -c config.json -p 443 --plugin v2ray-plugin --plugin-opts "tls"
```

### Shadowsocks over quic

On your server

```
ss-server -c config.json -p 443 --plugin v2ray-plugin --plugin-opts "server;mode=quic"
```

On your client

```
ss-local -c config.json -p 443 --plugin v2ray-plugin --plugin-opts "mode=quic"
```

## License

The MIT License (MIT)
