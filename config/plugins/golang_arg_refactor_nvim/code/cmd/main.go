package main

import (
	"fmt"
	"log"

	"github.com/back2nix/go-arg-propagation/pkg/coordinator"
)

func main() {
	coordinator := coordinator.NewMainCoordinator()
	functions := []string{
		"untouchedFunction",
	}

	argCounter := 1

	for _, funcName := range functions {
		argName := fmt.Sprintf("a%d", argCounter)
		err := coordinator.AddArgumentToFunction(
			"../code_dum/main.go",
			funcName,
			argName,
			"int",
		)
		if err != nil {
			log.Fatalf("Error adding argument to %s: %v", funcName, err)
		}
		argCounter++
	}
}
