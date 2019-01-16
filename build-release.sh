#!/bin/bash
sum="sha1sum"

if ! hash sha1sum 2>/dev/null; then
	if ! hash shasum 2>/dev/null; then
		echo "I can't see 'sha1sum' or 'shasum'"
		echo "Please install one of them!"
		exit
	fi
	sum="shasum"
fi

UPX=false
if hash upx 2>/dev/null; then
	UPX=true
fi

VERSION=`date -u +%Y%m%d`
LDFLAGS="-X main.VERSION=$VERSION -s -w"
GCFLAGS=""

OSES=(linux darwin windows freebsd)
ARCHS=(amd64 386)

# Get go
go get -u v2ray.com/core/...
go get -u v2ray.com/ext/...

for os in ${OSES[@]}; do
	for arch in ${ARCHS[@]}; do
		suffix=""
		if [ "$os" == "windows" ]
		then
			suffix=".exe"
		fi
		env CGO_ENABLED=0 GOOS=$os GOARCH=$arch go build -ldflags "$LDFLAGS" -gcflags "$GCFLAGS" -o v2ray-plugin_${os}_${arch}${suffix}
		if $UPX; then upx -9 v2ray-plugin_${os}_${arch}${suffix};fi
		tar -zcf v2ray-plugin-${os}-${arch}-$VERSION.tar.gz v2ray-plugin_${os}_${arch}${suffix}
		$sum v2ray-plugin-${os}-${arch}-$VERSION.tar.gz
	done
done

# ARM
ARMS=(5 6 7)
for v in ${ARMS[@]}; do
	env CGO_ENABLED=0 GOOS=linux GOARCH=arm GOARM=$v go build -ldflags "$LDFLAGS" -gcflags "$GCFLAGS" -o v2ray-plugin_linux_arm$v
done
if $UPX; then upx -9 v2ray-plugin_linux_arm*;fi
tar -zcf v2ray-plugin-linux-arm-$VERSION.tar.gz v2ray-plugin_linux_arm*
$sum v2ray-plugin-linux-arm-$VERSION.tar.gz

# MIPS
MIPSS=(mips mipsle)
for v in ${MIPSS[@]}; do
	env CGO_ENABLED=0 GOOS=linux GOARCH=$v go build -ldflags "$LDFLAGS" -gcflags "$GCFLAGS" -o v2ray-plugin_linux_$v
done
if $UPX; then upx -9 v2ray-plugin_linux_mips*;fi
tar -zcf v2ray-plugin-linux-mips-$VERSION.tar.gz v2ray-plugin_linux_mips*
$sum v2ray-plugin-linux-mips-$VERSION.tar.gz
