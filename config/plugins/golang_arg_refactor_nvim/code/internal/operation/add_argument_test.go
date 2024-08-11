package operation_test

import (
	"io/ioutil"
	"os"
	"path/filepath"
	"testing"

	"github.com/back2nix/golang_arg_refactor_nvim/internal/operation"
)

func TestAddArgumentComplex(t *testing.T) {
	// Create a temporary directory for test files
	tempDir, err := ioutil.TempDir("", "addargument_complex_test")
	if err != nil {
		t.Fatalf("Failed to create temp directory: %v", err)
	}
	defer os.RemoveAll(tempDir)

	// Create test file
	testFile := `package main

import (
	"fmt"
)

func main() {
	result := outerFunction(10, z)
	fmt.Println("Result:", result)
}

func outerFunction(a, b int) int {
	return middleFunction(a, b, func(x, y int) int {
		return innerFunction(x, y)
	})
}

func middleFunction(a, b int, operation func(int, int) int) int {
	return operation(a, b)
}

func innerFunction(x, y int) int {
	return add(x, y)
}

func add(x, y int) int {
	return x + y
}
`

	filePath := filepath.Join(tempDir, "main.go")
	err = ioutil.WriteFile(filePath, []byte(testFile), 0o644)
	if err != nil {
		t.Fatalf("Failed to write test file: %v", err)
	}

	// Prepare the request
	req := operation.AddArgumentRequest{
		TargetFunc: "add",
		ArgName:    "z",
		ArgType:    "int",
		MaxDepth:   5,
	}

	// Run the AddArgument function
	err = operation.AddArgument(req, []string{filePath})
	if err != nil {
		t.Fatalf("AddArgument failed: %v", err)
	}

	// Read the modified file
	modifiedContent, err := ioutil.ReadFile(filePath)
	if err != nil {
		t.Fatalf("Failed to read modified file: %v", err)
	}

	// Expected content after modification
	expectedContent := `package main

import (
	"fmt"
)

func main() {
	result := outerFunction(10, 20, z)
	fmt.Println("Result:", result)
}
func outerFunction(a, b, z int) int {
	return middleFunction(a, b, z, func(x, y, z int) int {
		return innerFunction(x, y, z)
	})
}
func middleFunction(a, b, z int, operation func(int, int, int) int) int {
	return operation(a, b, z)
}
func innerFunction(x, y, z int) int {
	return add(x, y, z)
}
func add(x, y, z int) int {
	return x + y
}
`

	// Compare modified content with expected content
	if string(modifiedContent) != expectedContent {
		t.Errorf("Modified content does not match expected content.\nGot:\n%s\nWant:\n%s",
			string(modifiedContent),
			expectedContent,
		)
	}
}
