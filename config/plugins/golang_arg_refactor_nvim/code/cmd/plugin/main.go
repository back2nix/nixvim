package main

import (
	"fmt"
	"log"
	"os"
	"strings"

	"github.com/neovim/go-client/nvim"

	"github.com/back2nix/go-arg-propagation/pkg/coordinator"
)

func addArgument(v *nvim.Nvim, args []string) (string, error) {
	if len(args) != 2 {
		return "", v.WriteErr("Usage: AddArgument <arg_name> <arg_type>")
	}

	argName := args[0]
	argType := args[1]

	// Get current buffer
	buffer, err := v.CurrentBuffer()
	if err != nil {
		return "1", fmt.Errorf("failed to get current buffer: %v", err)
	}

	// Get cursor position
	window, err := v.CurrentWindow()
	if err != nil {
		return "2", fmt.Errorf("failed to get current window: %v", err)
	}
	cursor, err := v.WindowCursor(window)
	if err != nil {
		return "3", fmt.Errorf("failed to get cursor position: %v", err)
	}

	// Get current line
	lines, err := v.BufferLines(buffer, cursor[0]-1, cursor[0], true)
	if err != nil || len(lines) == 0 {
		return "4", fmt.Errorf("failed to get current line: %v", err)
	}
	line := string(lines[0])

	// Extract word under cursor
	funcName := extractFunctionName(line, cursor[1])
	if funcName == "" {
		return "5", v.WriteErr("Couldn't find word under cursor")
	}

	// Get file path
	bufferName, err := v.BufferName(buffer)
	if err != nil {
		return "6", fmt.Errorf("failed to get buffer name: %v", err)
	}

	// Use the coordinator to add the argument
	coordinator := coordinator.NewMainCoordinator()
	err = coordinator.AddArgumentToFunction(bufferName, funcName, argName, argType)
	if err != nil {
		return "7", v.WriteErr(fmt.Sprintf("Error adding argument: %v", err))
	}

	return funcName + " " + argName + " " + argType, nil

	return "", v.WriteOut(
		fmt.Sprintf("Successfully added argument '%s' of type '%s' to function '%s'\n", argName, argType, funcName),
	)
}

func extractFunctionName(line string, cursorColumn int) string {
	// Находим подстроку от курсора до конца строки
	subLine := line[cursorColumn:]

	// Ищем первую открывающую скобку
	endIndex := strings.Index(subLine, "(")

	if endIndex == -1 {
		// Если скобка не найдена, возвращаем всю подстроку
		return strings.TrimSpace(subLine)
	}

	// Возвращаем подстроку до скобки, удаляя лишние пробелы
	return strings.TrimSpace(subLine[:endIndex])
}

func main() {
	log.SetFlags(0)
	stdout := os.Stdout
	os.Stdout = os.Stderr

	v, err := nvim.New(os.Stdin, stdout, stdout, log.Printf)
	if err != nil {
		log.Fatal(err)
	}

	v.RegisterHandler("addArgument", addArgument)

	if err := v.Serve(); err != nil {
		log.Fatal(err)
	}
}
