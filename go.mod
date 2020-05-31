module github.com/shadowsocks/v2ray-plugin

require (
	github.com/golang/mock v1.3.1 // indirect
	github.com/golang/protobuf v1.3.2
	github.com/google/go-cmp v0.3.0 // indirect
	github.com/miekg/dns v1.1.14 // indirect
	golang.org/x/crypto v0.0.0-20190618222545-ea8f1a30c443 // indirect
	golang.org/x/net v0.0.0-20190619014844-b5b0513f8c1b // indirect
	golang.org/x/sys v0.0.0-20190619223125-e40ef342dc56 // indirect
	golang.org/x/text v0.3.2 // indirect
	google.golang.org/genproto v0.0.0-20190611190212-a7e196e89fd3 // indirect
	v2ray.com/core v4.19.1+incompatible
)

replace v2ray.com/core => github.com/v2ray/v2ray-core v4.23.2+incompatible

go 1.13
