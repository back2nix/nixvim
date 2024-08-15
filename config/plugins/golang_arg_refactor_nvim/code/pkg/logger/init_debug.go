//go:build debug
// +build debug

package logger

import (
	"fmt"
)

func init() {
	var err error
	Log, err = NewLogger(true)
	if err != nil {
		fmt.Println("Error initializing debug logger:", err)
	}
	fmt.Println("Debug mode initialized")
}
