package main

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"

	"github.com/neovim/go-client/nvim"
)

func moveCode(v *nvim.Nvim, args []string) error {
	if len(args) != 1 {
		return fmt.Errorf("Expected 1 argument (destination path), got %d", len(args))
	}
	destPath := args[0]

	// Get current buffer and its file path
	buffer, err := v.CurrentBuffer()
	if err != nil {
		return fmt.Errorf("Failed to get current buffer: %v", err)
	}
	currentFilePath, err := v.BufferName(buffer)
	if err != nil {
		return fmt.Errorf("Failed to get current file path: %v", err)
	}

	// Find project root
	projectRoot, err := findProjectRoot(currentFilePath)
	if err != nil {
		return fmt.Errorf("Failed to find project root: %v", err)
	}

	// Process and validate the destination path
	fullDestPath, err := processDestinationPath(destPath, currentFilePath, projectRoot)
	if err != nil {
		return fmt.Errorf("Invalid destination path: %v", err)
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

	// Find code boundaries
	startLine, endLine, codeType := findCodeBoundaries(lines, cursor[0]-1)
	if startLine == -1 || endLine == -1 {
		return fmt.Errorf("No movable code found at cursor position")
	}

	// Extract code text
	codeLines := lines[startLine : endLine+1]
	codeText := strings.Join(bytesSliceToStringSlice(codeLines), "\n")

	// Ensure destination directory exists
	destDir := filepath.Dir(fullDestPath)
	if err := os.MkdirAll(destDir, 0o755); err != nil {
		return fmt.Errorf("Failed to create destination directory: %v", err)
	}

	// Check if the destination file is a new .go file
	isNewGoFile := !fileExists(fullDestPath) && strings.HasSuffix(fullDestPath, ".go")

	// Open the destination file
	f, err := os.OpenFile(fullDestPath, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0o644)
	if err != nil {
		return fmt.Errorf("Failed to open destination file: %v", err)
	}
	defer f.Close()

	// If it's a new .go file, add package declaration
	if isNewGoFile {
		packageName := filepath.Base(filepath.Dir(fullDestPath))
		packageDeclaration := fmt.Sprintf("package %s\n\n", packageName)
		if _, err := f.WriteString(packageDeclaration); err != nil {
			return fmt.Errorf("Failed to write package declaration: %v", err)
		}
	}

	// Write the code to the file
	if _, err := f.WriteString(codeText + "\n"); err != nil {
		return fmt.Errorf("Failed to write code to destination file: %v", err)
	}

	// Remove code from source file
	if err := v.SetBufferLines(buffer, startLine, endLine+1, true, [][]byte{}); err != nil {
		return fmt.Errorf("Failed to remove code from source file: %v", err)
	}

	return v.WriteOut(fmt.Sprintf("%s moved to %s\n", strings.Title(codeType), fullDestPath))
}

func findCodeBoundaries(lines [][]byte, cursorLine int) (int, int, string) {
	startLine := -1
	endLine := -1
	codeType := ""
	braceCount := 0

	// Search backwards for the start of the code block
	for i := cursorLine; i >= 0; i-- {
		line := string(lines[i])
		trimmedLine := strings.TrimSpace(line)
		if strings.HasPrefix(trimmedLine, "func ") {
			startLine = i
			codeType = "function"
			break
		} else if strings.HasPrefix(trimmedLine, "type ") && strings.Contains(trimmedLine, "struct") {
			startLine = i
			codeType = "struct"
			break
		} else if strings.HasPrefix(trimmedLine, "type ") && strings.Contains(trimmedLine, "interface") {
			startLine = i
			codeType = "interface"
			break
		} else if strings.HasPrefix(trimmedLine, "var ") || strings.HasPrefix(trimmedLine, "const ") {
			startLine = i
			codeType = "variable"
			break
		}
	}

	if startLine == -1 {
		return -1, -1, ""
	}

	// Search forwards for the end of the code block
	for i := startLine; i < len(lines); i++ {
		line := string(lines[i])
		braceCount += strings.Count(line, "{") - strings.Count(line, "}")
		if braceCount == 0 {
			if codeType == "variable" {
				if strings.TrimSpace(line) == ")" || !strings.Contains(line, ",") {
					endLine = i
					break
				}
			} else if strings.TrimSpace(line) == "}" {
				endLine = i
				break
			}
		}
	}

	return startLine, endLine, codeType
}

func findProjectRoot(startPath string) (string, error) {
	dir := filepath.Dir(startPath)
	for dir != "/" {
		if _, err := os.Stat(filepath.Join(dir, ".git")); err == nil {
			return dir, nil
		}
		dir = filepath.Dir(dir)
	}
	return "", fmt.Errorf("Project root not found")
}

func processDestinationPath(destPath, currentFilePath, projectRoot string) (string, error) {
	var fullPath string

	if filepath.IsAbs(destPath) {
		// For absolute paths, ensure they start with the project root
		fullPath = filepath.Join(projectRoot, destPath)
	} else if strings.HasPrefix(destPath, "/") {
		// Paths starting with "/" are relative to the project root
		fullPath = filepath.Join(projectRoot, destPath)
	} else {
		// Other paths are relative to the current file
		fullPath = filepath.Join(filepath.Dir(currentFilePath), destPath)
	}

	// Normalize the path
	fullPath = filepath.Clean(fullPath)

	// Ensure the path is within the project root
	if !strings.HasPrefix(fullPath, projectRoot) {
		return "", fmt.Errorf("Destination path is outside of the project root")
	}

	return fullPath, nil
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

func fileExists(filename string) bool {
	_, err := os.Stat(filename)
	return !os.IsNotExist(err)
}

func main() {
	log.SetFlags(0)
	stdout := os.Stdout
	os.Stdout = os.Stderr

	v, err := nvim.New(os.Stdin, stdout, stdout, log.Printf)
	if err != nil {
		log.Fatal(err)
	}

	v.RegisterHandler("moveCode", moveCode)

	if err := v.Serve(); err != nil {
		log.Fatal(err)
	}
}
