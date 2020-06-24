module github.com/shadowsocks/v2ray-plugin

require (
	github.com/golang/protobuf v1.4.2
	golang.org/x/text v0.3.2 // indirect
	v2ray.com/core v4.19.1+incompatible
)

replace v2ray.com/core => github.com/v2ray/v2ray-core v4.25.1+incompatible

go 1.13

