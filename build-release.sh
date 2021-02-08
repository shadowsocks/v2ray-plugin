#!/bin/bash

# Detect Operating System
function dist-check() {
    if [ -e /etc/os-release ]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        DISTRO=$ID
    fi
}

# Check Operating System
dist-check

# Pre-Checks system requirements
function installing-system-requirements() {
    if { [ "$DISTRO" == "ubuntu" ] || [ "$DISTRO" == "debian" ] || [ "$DISTRO" == "raspbian" ] || [ "$DISTRO" == "pop" ] || [ "$DISTRO" == "kali" ] || [ "$DISTRO" == "linuxmint" ] || [ "$DISTRO" == "fedora" ] || [ "$DISTRO" == "centos" ] || [ "$DISTRO" == "rhel" ] || [ "$DISTRO" == "arch" ] || [ "$DISTRO" == "manjaro" ] || [ "$DISTRO" == "alpine" ] || [ "$DISTRO" == "freebsd" ]; }; then
        if [ ! -x "$(command -v sha1sum)" ]; then
            if { [ "$DISTRO" == "ubuntu" ] || [ "$DISTRO" == "debian" ] || [ "$DISTRO" == "raspbian" ] || [ "$DISTRO" == "pop" ] || [ "$DISTRO" == "kali" ] || [ "$DISTRO" == "linuxmint" ]; }; then
                sudo apt-get update && apt-get install coreutils -y
            elif { [ "$DISTRO" == "fedora" ] || [ "$DISTRO" == "centos" ] || [ "$DISTRO" == "rhel" ]; }; then
                sudo yum update -y && yum install coreutils -y
            elif { [ "$DISTRO" == "arch" ] || [ "$DISTRO" == "manjaro" ]; }; then
                sudo pacman -Syu --noconfirm iptables coreutils
            elif [ "$DISTRO" == "alpine" ]; then
                sudo apk update && apk add coreutils
            elif [ "$DISTRO" == "freebsd" ]; then
                sudo pkg update && pkg install coreutils
            fi
        fi
    else
        echo "Error: $DISTRO not supported."
        exit
    fi
}

# Run the function and check for requirements
installing-system-requirements

# Build for all the OS
function build-golang-app() {
    if [ -x "$(command -v go)" ]; then
        GOOS=aix GOARCH=ppc64 go build -o build/aix-ppc64 .
        GOOS=android GOARCH=386 go build -o build/android-386 .
        GOOS=android GOARCH=amd64 go build -o build/android-amd64 .
        GOOS=android GOARCH=arm go build -o build/android-arm .
        GOOS=android GOARCH=arm64 go build -o build/android-arm64 .
        GOOS=darwin GOARCH=386 go build -o build/darwin-386 .
        GOOS=darwin GOARCH=amd64 go build -o build/darwin-amd64 .
        GOOS=darwin GOARCH=arm go build -o build/darwin-arm .
        GOOS=darwin GOARCH=arm64 go build -o build/darwin-arm64 .
        GOOS=dragonfly GOARCH=amd64 go build -o build/dragonfly-amd64 .
        GOOS=freebsd GOARCH=386 go build -o build/freebsd-386 .
        GOOS=freebsd GOARCH=amd64 go build -o build/freebsd-amd64 .
        GOOS=freebsd GOARCH=arm go build -o build/freebsd-arm .
        GOOS=freebsd GOARCH=arm64 go build -o build/freebsd-arm64 .
        GOOS=js GOARCH=wasm go build -o build/js-wasm .
        GOOS=illumos GOARCH=amd64 go build -o build/amd64 .
        GOOS=linux GOARCH=386 go build -o build/linux-386 .
        GOOS=linux GOARCH=amd64 go build -o build/linux-amd64 .
        GOOS=linux GOARCH=arm go build -o build/linux-arm .
        GOOS=linux GOARCH=arm64 go build -o build/linux-arm64 .
        GOOS=linux GOARCH=mips go build -o build/linux-mips .
        GOOS=linux GOARCH=mips64 go build -o build/linux-mips64 .
        GOOS=linux GOARCH=mips64le go build -o build/linux-mips64le .
        GOOS=linux GOARCH=mipsle go build -o build/linux-mipsle .
        GOOS=linux GOARCH=ppc64 go build -o build/linux-ppc64 .
        GOOS=linux GOARCH=ppc64le go build -o build/linux-ppc64le .
        GOOS=linux GOARCH=riscv64 go build -o build/linux-riscv64 .
        GOOS=linux GOARCH=s390x go build -o build/linux-s390x .
        GOOS=nacl GOARCH=386 go build -o build/nacl-386 .
        GOOS=nacl GOARCH=amd64p32 go build -o build/nacl-amd64p32 .
        GOOS=nacl GOARCH=nacl-arm go build -o build/nacl-arm .
        GOOS=netbsd GOARCH=386 go build -o build/netbsd-386 .
        GOOS=netbsd GOARCH=amd64 go build -o build/netbsd-amd64 .
        GOOS=netbsd GOARCH=arm go build -o build/netbsd-arm .
        GOOS=netbsd GOARCH=arm64 go build -o build/netbsd-arm64 .
        GOOS=openbsd GOARCH=386 go build -o build/openbsd-386 .
        GOOS=openbsd GOARCH=amd64 go build -o build/openbsd-amd64 .
        GOOS=openbsd GOARCH=arm go build -o build/openbsd-arm .
        GOOS=openbsd GOARCH=arm64 go build -o build/openbsd-arm64 .
        GOOS=plan9 GOARCH=386 go build -o build/plan9-386 .
        GOOS=plan9 GOARCH=amd64 go build -o build/plan9-amd64 .
        GOOS=plan9 GOARCH=arm go build -o build/plan9-arm .
        GOOS=solaris GOARCH=amd64 go build -o build/solaris-amd64 .
        GOOS=windows GOARCH=386 go build -o build/windows-386 .
        GOOS=windows GOARCH=amd64 go build -o build/windows-amd64 .
        GOOS=windows GOARCH=arm go build -o build/windows-arm .
        echo "$(find build/ -type f -print0 | xargs -0 sha1sum)" >>SHA-1
    else
        echo "Error: In your system, Go wasn't found."
        exit
    fi
}

# Start the build
build-golang-app
