package main

import (
	"log"

	"github.com/back2nix/go-arg-propagation/pkg/coordinator"
)

func main() {
	coordinator := coordinator.NewMainCoordinator()
	err := coordinator.AddArgumentToFunction(
		"./example/change_me.go",
		"untouchedFunction",
		"my_new_arg",
		"int",
	)
	if err != nil {
		log.Fatalf("Error adding argument to %v", err)
	}
}
