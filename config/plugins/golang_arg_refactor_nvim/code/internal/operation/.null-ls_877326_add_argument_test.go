package operation_test

import (
	"io/ioutil"
	"os"
	"path/filepath"
	"testing"

	"github.com/back2nix/golang_arg_refactor_nvim/internal/operation"
)

func TestAddArgument(t *testing.T) {
	// Create a temporary directory for test files
	tempDir, err := ioutil.TempDir("", "addargument_test")
	if err != nil {
		t.Fatalf("Failed to create temp directory: %v", err)
	}
	defer os.RemoveAll(tempDir)

	// Create test files
	files := map[string]string{
		"main.go": `
package main

func main() {
	result := calculateTotal(10, 20)
	println(result)
}

func calculateTotal(a, b int) int {
	return add(a, b)
}

func add(x, y int) int {
	return x + y
}
`,
	}

	for name, content := range files {
		err := ioutil.WriteFile(filepath.Join(tempDir, name), []byte(content), 0644)
		if err != nil {
			t.Fatalf("Failed to write test file: %v", err)
		}
	}

	// Prepare the request
	req := operation.AddArgumentRequest{
		TargetFunc: "add",
		ArgName:    "z",
		ArgType:    "int",
		MaxDepth:   2,
	}

	// Run the AddArgument function
	err = operation.AddArgument(req, []string{filepath.Join(tempDir, "main.go")})
	if err != nil {
		t.Fatalf("AddArgument failed: %v", err)
	}

	// Read the modified file
	modifiedContent, err := ioutil.ReadFile(filepath.Join(tempDir, "main.go"))
	if err != nil {
		t.Fatalf("Failed to read modified file: %v", err)
	}

	// Expected content after modification
	expectedContent := `
package main

func main() {
	result := calculateTotal(10, 20, 0)
	println(result)
}

func calculateTotal(a, b, z int) int {
	return add(a, b, z)
}

func add(x, y, z int) int {
	return x + y
}
`

	// Compare modified content with expected content
	if string(modifiedContent) != expectedContent {
		t.Errorf("Modified content does not match expected content.\nGot:\n%s\nWant:\n%s", string(modifiedContent), expectedContent)
	}
}
