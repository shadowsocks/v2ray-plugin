// Copyright 2014 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// +build !android

package main

import "log"

func logInit() {
}

func logFatal(v ...interface{}) {
	log.Println(v...)
}

func logWarn(v ...interface{}) {
	log.Println(v...)
}

func logInfo(v ...interface{}) {
	log.Println(v...)
}
