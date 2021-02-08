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
        if { [ ! -x "$(command -v sha1sum)" ] || [ ! -x "$(command -v shasum)" ]; }; then
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
        GOOS=darwin GOARCH=386 go build -o build/darwin-386 .
        GOOS=darwin GOARCH=amd64 go build -o build/darwin-amd64 .
        GOOS=windows GOARCH=386 go build -o build/windows-386.exe .
        GOOS=windows GOARCH=amd64 go build -o build/windows-amd64.exe .
        GOOS=windows GOARCH=arm go build -o build/windows-arm.exe .
        GOOS=freebsd GOARCH=386 go build -o build/freebsd-386 .
        GOOS=freebsd GOARCH=amd64 go build -o build/freebsd-amd64 .
        GOOS=freebsd GOARCH=arm go build -o build/freebsd-arm .
        GOOS=freebsd GOARCH=arm64 go build -o build/freebsd-arm64 .
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
        echo "$(find build/ -type f -print0 | xargs -0 sha1sum)" >>SHA-1
    else
        echo "Error: In your system, Go wasn't found."
        exit
    fi
}

# Start the build
build-golang-app
