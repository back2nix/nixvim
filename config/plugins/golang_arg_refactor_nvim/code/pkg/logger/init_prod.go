//go:build !debug
// +build !debug

package logger

import (
	"fmt"
)

func init() {
	var err error
	Log, err = NewLogger(false)
	if err != nil {
		fmt.Println("Error initializing production logger:", err)
	}
	fmt.Println("Production mode initialized")
}
