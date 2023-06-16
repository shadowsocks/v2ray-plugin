//go:build android
// +build android

package main

import (
	"fmt"
	"net"
	"syscall"

	vinternet "github.com/v2fly/v2ray-core/v4/transport/internet"
)

const netUnix = "unix"

var protectAddr = &net.UnixAddr{Net: netUnix, Name: "protect_path"}

func ControlOnConnSetup(network, address string, fd uintptr) error {
	conn, err := net.DialUnix(netUnix, nil, protectAddr)
	if err != nil {
		return err
	}
	defer conn.Close()

	rights := syscall.UnixRights(int(fd))
	dummy := []byte{1}
	n, ooBn, err := conn.WriteMsgUnix(dummy, rights, nil)
	if err != nil {
		return err
	}
	if n != 1 || ooBn != len(rights) {
		return fmt.Errorf("WriteMsgUnix = %d, %d; want 1, %d\n", n, ooBn, len(rights))
	}

	_, err = conn.Read(dummy)
	if err != nil {
		return err
	}
	if dummy[0] == 0xff {
		return fmt.Errorf("dummy[0] = %d", dummy[0])
	}
	return nil
}

func registerControlFunc() {
	vinternet.RegisterDialerController(ControlOnConnSetup)
	vinternet.RegisterListenerController(ControlOnConnSetup)
}
