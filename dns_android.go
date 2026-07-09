//go:build android && cgo
// +build android,cgo

package main

import "net"

func init() {
	net.DefaultResolver = &net.Resolver{}
}
