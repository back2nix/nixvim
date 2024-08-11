package main

import (
	"fmt"
	"log"
	"os"
	"path/filepath"

	"github.com/neovim/go-client/nvim"

	"github.com/back2nix/golang_arg_refactor_nvim/internal/analysis"
	"github.com/back2nix/golang_arg_refactor_nvim/internal/operation"
)

func main() {
	log.SetFlags(0)

	stdout := os.Stdout
	os.Stdout = os.Stderr

	v, err := nvim.New(os.Stdin, stdout, stdout, log.Printf)
	if err != nil {
		log.Fatal(err)
	}

	v.RegisterHandler("add_argument", handleAddArgument)
	v.RegisterHandler("remove_argument", handleRemoveArgument)

	if err := v.Serve(); err != nil {
		log.Fatal(err)
	}
}

func handleAddArgument(v *nvim.Nvim, args []string) error {
	if len(args) != 3 {
		return fmt.Errorf("expected 3 arguments: function name, argument name, argument type")
	}

	funcName, argName, argType := args[0], args[1], args[2]

	b, err := v.CurrentBuffer()
	if err != nil {
		return fmt.Errorf("failed to get current buffer: %w", err)
	}

	name, err := v.BufferName(b)
	if err != nil {
		return fmt.Errorf("failed to get buffer name: %w", err)
	}

	dir := filepath.Dir(name)
	files, err := analysis.GetAllGoFiles(dir)
	if err != nil {
		return fmt.Errorf("failed to get Go files: %w", err)
	}

	req := operation.AddArgumentRequest{
		TargetFunc: funcName,
		ArgName:    argName,
		ArgType:    argType,
		MaxDepth:   5, // You might want to make this configurable
	}

	if err := operation.AddArgument(req, files); err != nil {
		return fmt.Errorf("failed to add argument: %w", err)
	}

	return v.Command("edit!")
}

func handleRemoveArgument(v *nvim.Nvim, args []string) error {
	if len(args) != 2 {
		return fmt.Errorf("expected 2 arguments: function name, argument name")
	}

	funcName, argName := args[0], args[1]

	b, err := v.CurrentBuffer()
	if err != nil {
		return fmt.Errorf("failed to get current buffer: %w", err)
	}

	name, err := v.BufferName(b)
	if err != nil {
		return fmt.Errorf("failed to get buffer name: %w", err)
	}

	dir := filepath.Dir(name)
	files, err := analysis.GetAllGoFiles(dir)
	if err != nil {
		return fmt.Errorf("failed to get Go files: %w", err)
	}

	req := operation.RemoveArgumentRequest{
		TargetFunc: funcName,
		ArgName:    argName,
		MaxDepth:   5, // You might want to make this configurable
	}

	if err := operation.RemoveArgument(req, files); err != nil {
		return fmt.Errorf("failed to remove argument: %w", err)
	}

	return v.Command("edit!")
}
