package main

import (
	"encoding/json"
	"fmt"
	"log"
	"os"
	"strings"

	"github.com/neovim/go-client/nvim"

	"github.com/back2nix/go-arg-propagation/pkg/coordinator"
)

type Result struct {
	Success bool   `json:"success"`
	Message string `json:"message"`
	Error   string `json:"error,omitempty"`
}

func addArgument(v *nvim.Nvim, args []string) (string, error) {
	if len(args) != 2 {
		return encodeResult(false, "", "Usage: AddArgument <arg_name> <arg_type>")
	}
	argName := args[0]
	argType := args[1]

	buffer, err := v.CurrentBuffer()
	if err != nil {
		return encodeResult(false, "", fmt.Sprintf("Failed to get current buffer: %v", err))
	}

	window, err := v.CurrentWindow()
	if err != nil {
		return encodeResult(false, "", fmt.Sprintf("Failed to get current window: %v", err))
	}

	cursor, err := v.WindowCursor(window)
	if err != nil {
		return encodeResult(false, "", fmt.Sprintf("Failed to get cursor position: %v", err))
	}

	lines, err := v.BufferLines(buffer, cursor[0]-1, cursor[0], true)
	if err != nil || len(lines) == 0 {
		return encodeResult(false, "", fmt.Sprintf("Failed to get current line: %v", err))
	}
	line := string(lines[0])

	funcName := extractFunctionName(line, cursor[1])
	if funcName == "" {
		return encodeResult(false, "", "Couldn't find word under cursor")
	}

	bufferName, err := v.BufferName(buffer)
	if err != nil {
		return encodeResult(false, "", fmt.Sprintf("Failed to get buffer name: %v", err))
	}

	coordinator := coordinator.NewMainCoordinator()
	err = coordinator.AddArgumentToFunction(bufferName, funcName, argName, argType)
	if err != nil {
		return encodeResult(false, "", fmt.Sprintf("Error adding argument: %v", err))
	}

	// Обновляем буфер
	if err := v.Command("edit!"); err != nil {
		return encodeResult(false, "", fmt.Sprintf("Failed to refresh buffer: %v", err))
	}

	return encodeResult(
		true,
		fmt.Sprintf("Successfully added argument '%s' of type '%s' to function '%s'", argName, argType, funcName),
		"",
	)
}

func encodeResult(success bool, message, errMsg string) (string, error) {
	result := Result{
		Success: success,
		Message: message,
		Error:   errMsg,
	}
	jsonResult, err := json.Marshal(result)
	if err != nil {
		return "", fmt.Errorf("failed to encode result: %v", err)
	}
	return string(jsonResult), nil
}

func extractFunctionName(line string, cursorColumn int) string {
	// Находим начало имени функции/метода
	start := cursorColumn
	for start > 0 && (isLetter(line[start-1]) || isDigit(line[start-1]) || line[start-1] == '.' || line[start-1] == '_') {
		start--
	}

	// Находим конец имени функции/метода
	end := cursorColumn
	for end < len(line) && (isLetter(line[end]) || isDigit(line[end]) || line[end] == '.' || line[end] == '_') {
		end++
	}

	// Извлекаем имя функции/метода
	name := line[start:end]

	// Убираем receiver, если он есть
	if dotIndex := strings.LastIndex(name, "."); dotIndex != -1 {
		name = name[dotIndex+1:]
	}

	return name
}

// Вспомогательные функции
func isLetter(c byte) bool {
	return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
}

func isDigit(c byte) bool {
	return c >= '0' && c <= '9'
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
