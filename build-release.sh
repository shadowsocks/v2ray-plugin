#!/usr/bin/env bash

set -e

sum="sha1sum"

if ! hash sha1sum 2>/dev/null; then
    if ! hash shasum 2>/dev/null; then
        echo "I can't see 'sha1sum' or 'shasum'"
        echo "Please install one of them!"
        exit
    fi
    sum="shasum"
fi

if [[ -z $upx ]]; then
    upx="echo pending"
fi
if [[ $upx == "echo pending" ]] && hash upx 2>/dev/null; then
    upx="upx -9"
fi

VERSION=$(git describe --tags)
LDFLAGS="-X main.VERSION=$VERSION -s -w -buildid="

OSES=(linux darwin windows freebsd)
ARCHS=(amd64 386)

mkdir -p bin

for os in ${OSES[@]}; do
    for arch in ${ARCHS[@]}; do
        # Go 1.15 drops support for 32-bit binaries on macOS, iOS, iPadOS, watchOS, and tvOS (the darwin/386 and darwin/arm ports)
        # Reference URL: https://tip.golang.org/doc/go1.15#darwin
        if [ "$os" == "darwin" ] && [ "$arch" == "386" ]; then
            continue
        fi
        suffix=""
        if [ "$os" == "windows" ]; then
            suffix=".exe"
        fi
        env CGO_ENABLED=0 GOOS=$os GOARCH=$arch go build -mod=vendor -v -ldflags "$LDFLAGS" -o v2ray-plugin_${os}_${arch}${suffix}
        $upx v2ray-plugin_${os}_${arch}${suffix} >/dev/null 2>&1 || echo "upx: skipped (unsupported) for ${os}_${arch}"
        tar -zcf bin/v2ray-plugin-${os}-${arch}-$VERSION.tar.gz v2ray-plugin_${os}_${arch}${suffix}
        $sum bin/v2ray-plugin-${os}-${arch}-$VERSION.tar.gz
    done
done

# ARM
ARMS=(5 6 7)
for v in ${ARMS[@]}; do
	env CGO_ENABLED=0 GOOS=linux GOARCH=arm GOARM=$v go build -mod=vendor -v -ldflags "$LDFLAGS" -o v2ray-plugin_linux_arm$v
done
$upx v2ray-plugin_linux_arm* >/dev/null 2>&1 || echo "upx: skipped for linux_arm"
tar -zcf bin/v2ray-plugin-linux-arm-$VERSION.tar.gz v2ray-plugin_linux_arm*
$sum bin/v2ray-plugin-linux-arm-$VERSION.tar.gz

# ARM64 (ARMv8 or aarch64)
env CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -mod=vendor -v -ldflags "$LDFLAGS" -o v2ray-plugin_linux_arm64
$upx v2ray-plugin_linux_arm64 >/dev/null 2>&1 || echo "upx: skipped for linux_arm64"
tar -zcf bin/v2ray-plugin-linux-arm64-$VERSION.tar.gz v2ray-plugin_linux_arm64
$sum bin/v2ray-plugin-linux-arm64-$VERSION.tar.gz

# Darwin ARM64
env CGO_ENABLED=0 GOOS=darwin GOARCH=arm64 go build -mod=vendor -v -ldflags "$LDFLAGS" -o v2ray-plugin_darwin_arm64
$upx v2ray-plugin_darwin_arm64 >/dev/null 2>&1 || echo "upx: skipped for darwin_arm64"
tar -zcf bin/v2ray-plugin-darwin-arm64-$VERSION.tar.gz v2ray-plugin_darwin_arm64
$sum bin/v2ray-plugin-darwin-arm64-$VERSION.tar.gz

# MIPS
MIPSS=(mips mipsle)
for v in ${MIPSS[@]}; do
	env CGO_ENABLED=0 GOOS=linux GOARCH=$v go build -mod=vendor -v -ldflags "$LDFLAGS" -o v2ray-plugin_linux_$v
	env CGO_ENABLED=0 GOOS=linux GOARCH=$v GOMIPS=softfloat go build -mod=vendor -ldflags "$LDFLAGS" -o v2ray-plugin_linux_${v}_sf
done
$upx v2ray-plugin_linux_mips* >/dev/null 2>&1 || echo "upx: skipped for linux_mips"
tar -zcf bin/v2ray-plugin-linux-mips-$VERSION.tar.gz v2ray-plugin_linux_mips*
$sum bin/v2ray-plugin-linux-mips-$VERSION.tar.gz

# MIPS64
MIPS64S=(mips64 mips64le)
for v in ${MIPS64S[@]}; do
	env CGO_ENABLED=0 GOOS=linux GOARCH=$v go build -mod=vendor -v -ldflags "$LDFLAGS" -o v2ray-plugin_linux_$v
done
tar -zcf bin/v2ray-plugin-linux-mips64-$VERSION.tar.gz v2ray-plugin_linux_mips64*
$sum bin/v2ray-plugin-linux-mips64-$VERSION.tar.gz
