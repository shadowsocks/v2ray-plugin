// +build android

package main

/*
#cgo LDFLAGS: -landroid -llog

#include <android/log.h>
#include <stdlib.h>
#include <string.h>
*/
import "C"

import (
	"fmt"
	"unsafe"

	alog "github.com/v2fly/v2ray-core/v5/app/log"

	"github.com/v2fly/v2ray-core/v5/common"
	"github.com/v2fly/v2ray-core/v5/common/log"
	"github.com/v2fly/v2ray-core/v5/common/serial"
)

var (
	ctag = C.CString("v2ray")
)

type androidLogger struct{}

func (l *androidLogger) Handle(msg log.Message) {
	var priority = C.ANDROID_LOG_FATAL // this value should never be used in client mode
	var message string
	switch msg := msg.(type) {
	case *log.GeneralMessage:
		switch msg.Severity {
		case log.Severity_Error:
			priority = C.ANDROID_LOG_ERROR
		case log.Severity_Warning:
			priority = C.ANDROID_LOG_WARN
		case log.Severity_Info:
			priority = C.ANDROID_LOG_INFO
		case log.Severity_Debug:
			priority = C.ANDROID_LOG_DEBUG
		}
		message = serial.ToString(msg.Content)
	default:
		message = msg.String()
	}
	cstr := C.CString(message)
	defer C.free(unsafe.Pointer(cstr))
	C.__android_log_write(C.int(priority), ctag, cstr)
}

func logInit() {
	common.Must(alog.RegisterHandlerCreator(alog.LogType_Console, func(_ alog.LogType, _ alog.HandlerCreatorOptions) (log.Handler, error) {
		return &androidLogger{}, nil
	}))
}

func logFatal(v ...interface{}) {
	cstr := C.CString(fmt.Sprintln(v...))
	defer C.free(unsafe.Pointer(cstr))
	C.__android_log_write(C.ANDROID_LOG_FATAL, ctag, cstr)
}

func logWarn(v ...interface{}) {
	(&androidLogger{}).Handle(&log.GeneralMessage{Severity: log.Severity_Warning, Content: fmt.Sprintln(v...)})
}

func logInfo(v ...interface{}) {
	(&androidLogger{}).Handle(&log.GeneralMessage{Severity: log.Severity_Info, Content: fmt.Sprintln(v...)})
}
