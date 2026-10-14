//go:build amd64 && !noasm
// +build amd64,!noasm

package p384

import "golang.org/x/sys/cpu"

var hasBMI2 = cpu.X86.HasBMI2 //nolint
