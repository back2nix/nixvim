package main

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"

	"github.com/neovim/go-client/nvim"
)

func moveFunction(v *nvim.Nvim, args []string) error {
	if len(args) != 1 {
		return fmt.Errorf("Expected 1 argument (destination path), got %d", len(args))
	}
	destPath := args[0]

	// Get current buffer
	buffer, err := v.CurrentBuffer()
	if err != nil {
		return fmt.Errorf("Failed to get current buffer: %v", err)
	}

	// Get cursor position
	window, err := v.CurrentWindow()
	if err != nil {
		return fmt.Errorf("Failed to get current window: %v", err)
	}
	cursor, err := v.WindowCursor(window)
	if err != nil {
		return fmt.Errorf("Failed to get cursor position: %v", err)
	}

	// Get buffer contents
	lines, err := v.BufferLines(buffer, 0, -1, true)
	if err != nil {
		return fmt.Errorf("Failed to get buffer lines: %v", err)
	}

	// Find function boundaries
	startLine, endLine := findFunctionBoundaries(lines, cursor[0]-1)
	if startLine == -1 || endLine == -1 {
		return fmt.Errorf("No function found at cursor position")
	}

	// Extract function text
	functionLines := lines[startLine : endLine+1]
	functionText := strings.Join(bytesSliceToStringSlice(functionLines), "\n")

	// Ensure destination directory exists
	destDir := filepath.Dir(destPath)
	if err := os.MkdirAll(destDir, 0o755); err != nil {
		return fmt.Errorf("Failed to create destination directory: %v", err)
	}

	// Append function to destination file
	f, err := os.OpenFile(destPath, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0o644)
	if err != nil {
		return fmt.Errorf("Failed to open destination file: %v", err)
	}
	defer f.Close()

	if _, err := f.WriteString("\n" + functionText + "\n"); err != nil {
		return fmt.Errorf("Failed to write function to destination file: %v", err)
	}

	// Remove function from source file
	if err := v.SetBufferLines(buffer, startLine, endLine+1, true, [][]byte{}); err != nil {
		return fmt.Errorf("Failed to remove function from source file: %v", err)
	}

	return v.WriteOut(fmt.Sprintf("Function moved to %s\n", destPath))
}

func findFunctionBoundaries(lines [][]byte, cursorLine int) (int, int) {
	startLine := -1
	endLine := -1
	braceCount := 0

	// Search backwards for function start
	for i := cursorLine; i >= 0; i-- {
		if strings.HasPrefix(string(lines[i]), "func ") {
			startLine = i
			break
		}
	}

	if startLine == -1 {
		return -1, -1
	}

	// Search forwards for function end
	for i := startLine; i < len(lines); i++ {
		line := string(lines[i])
		braceCount += strings.Count(line, "{") - strings.Count(line, "}")
		if braceCount == 0 && strings.TrimSpace(line) == "}" {
			endLine = i
			break
		}
	}

	return startLine, endLine
}

func bytesSliceToStringSlice(bytesSlice [][]byte) []string {
	result := make([]string, len(bytesSlice))
	for i, b := range bytesSlice {
		result[i] = string(b)
	}
	return result
}

func main() {
	log.SetFlags(0)
	stdout := os.Stdout
	os.Stdout = os.Stderr

	v, err := nvim.New(os.Stdin, stdout, stdout, log.Printf)
	if err != nil {
		log.Fatal(err)
	}

	v.RegisterHandler("moveFunction", moveFunction)

	if err := v.Serve(); err != nil {
		log.Fatal(err)
	}
}
