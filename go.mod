module github.com/shadowsocks/v2ray-plugin

require (
	github.com/golang/mock v1.4.0 // indirect
	github.com/golang/protobuf v1.3.3
	github.com/google/go-cmp v0.4.0 // indirect
	github.com/miekg/dns v1.1.27 // indirect
	golang.org/x/text v0.3.2 // indirect
	google.golang.org/genproto v0.0.0-20190611190212-a7e196e89fd3 // indirect
	v2ray.com/core v4.19.1+incompatible
)

replace v2ray.com/core => github.com/v2ray/v2ray-core v4.22.1+incompatible

go 1.13
