package main

import (
	"context"
	"fmt"
	"os"
	"os/signal"
	"runtime"
	"syscall"

	"github.com/back2nix/speaker/internal/localinput"
	"github.com/back2nix/speaker/internal/translateshell"
)

func main() {
	ctx, cancel := context.WithCancel(context.Background())

	sigs := make(chan os.Signal, 1)
	signal.Notify(sigs, syscall.SIGINT, syscall.SIGTERM)
	go func() {
		sig := <-sigs
		fmt.Println()
		fmt.Println(sig)
		cancel()
		os.Exit(0)
	}()

	trShell := translateshell.New(ctx)
	go trShell.Run()

	if os.Getenv("WAYLAND_DISPLAY") != "" {
		fmt.Println("Using Wayland")
	} else if runtime.GOOS == "darwin" { // macOS
		fmt.Println("Using macOS")
	} else {
		fmt.Println("Using X11")
	}
	err := localinput.Start(cancel, trShell)
	if err != nil {
		panic(err)
	}
}
