package analysis

import (
	"io/ioutil"
	"os"
	"path/filepath"
	"reflect"
	"testing"
)

func TestGetAllGoFiles(t *testing.T) {
	// Create a temporary directory structure
	tempDir, err := ioutil.TempDir("", "test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	// Create test files
	files := []string{
		filepath.Join(tempDir, "file1.go"),
		filepath.Join(tempDir, "file2.go"),
		filepath.Join(tempDir, "subdir", "file3.go"),
		filepath.Join(tempDir, "file4.txt"),
	}

	for _, file := range files {
		dir := filepath.Dir(file)
		if err := os.MkdirAll(dir, 0o755); err != nil {
			t.Fatalf("Failed to create directory: %v", err)
		}
		if err := ioutil.WriteFile(file, []byte(""), 0o644); err != nil {
			t.Fatalf("Failed to create file: %v", err)
		}
	}

	// Test GetAllGoFiles
	gotFiles, err := GetAllGoFiles(tempDir)
	if err != nil {
		t.Fatalf("GetAllGoFiles failed: %v", err)
	}

	expectedFiles := []string{
		filepath.Join(tempDir, "file1.go"),
		filepath.Join(tempDir, "file2.go"),
		filepath.Join(tempDir, "subdir", "file3.go"),
	}

	if !reflect.DeepEqual(gotFiles, expectedFiles) {
		t.Errorf("GetAllGoFiles() = %v, want %v", gotFiles, expectedFiles)
	}

	// Test error handling
	_, err = GetAllGoFiles("/nonexistent")
	if err == nil {
		t.Error("Expected error for non-existent directory, got nil")
	}
}

func TestAnalyzeCallChain(t *testing.T) {
	// Create temporary Go files
	tempDir, err := ioutil.TempDir("", "test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	file1 := `
package main

func main() {
	foo()
}

func foo() {
	bar()
}

func bar() {
	baz()
}

func baz() {
}
`
	file2 := `
package main

func qux() {
	foo()
}
`

	if err := ioutil.WriteFile(filepath.Join(tempDir, "file1.go"), []byte(file1), 0o644); err != nil {
		t.Fatalf("Failed to write file1: %v", err)
	}
	if err := ioutil.WriteFile(filepath.Join(tempDir, "file2.go"), []byte(file2), 0o644); err != nil {
		t.Fatalf("Failed to write file2: %v", err)
	}

	files, err := GetAllGoFiles(tempDir)
	if err != nil {
		t.Fatalf("Failed to get Go files: %v", err)
	}

	// Test simple call chain
	chain, err := AnalyzeCallChain("baz", files, 3)
	if err != nil {
		t.Fatalf("AnalyzeCallChain failed: %v", err)
	}

	expectedChain := CallChain{
		Function: "baz",
		Callers:  []string{"bar", "foo", "main"},
	}

	if !reflect.DeepEqual(chain, expectedChain) {
		t.Errorf("AnalyzeCallChain() = %v, want %v", chain, expectedChain)
	}

	// Test max depth
	chain, err = AnalyzeCallChain("baz", files, 1)
	if err != nil {
		t.Fatalf("AnalyzeCallChain failed: %v", err)
	}

	expectedChain = CallChain{
		Function: "baz",
		Callers:  []string{"bar"},
	}

	if !reflect.DeepEqual(chain, expectedChain) {
		t.Errorf("AnalyzeCallChain() with max depth = %v, want %v", chain, expectedChain)
	}

	// Test non-existent function
	chain, err = AnalyzeCallChain("nonexistent", files, 3)
	if err != nil {
		t.Fatalf("AnalyzeCallChain failed: %v", err)
	}

	expectedChain = CallChain{
		Function: "nonexistent",
		Callers:  []string{},
	}

	if !reflect.DeepEqual(chain, expectedChain) {
		t.Errorf("AnalyzeCallChain() for non-existent function = %v, want %v", chain, expectedChain)
	}

	// Test error handling
	_, err = AnalyzeCallChain("baz", []string{"nonexistent.go"}, 3)
	if err == nil {
		t.Error("Expected error for non-existent file, got nil")
	}
}

func TestAnalyzeCallChainWithRecursion(t *testing.T) {
	tempDir, err := ioutil.TempDir("", "test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	fileContent := `
package main

func recursive(n int) {
	if n > 0 {
		recursive(n - 1)
	}
}

func main() {
	recursive(5)
}
`

	if err := ioutil.WriteFile(filepath.Join(tempDir, "recursive.go"), []byte(fileContent), 0o644); err != nil {
		t.Fatalf("Failed to write recursive.go: %v", err)
	}

	files, err := GetAllGoFiles(tempDir)
	if err != nil {
		t.Fatalf("Failed to get Go files: %v", err)
	}

	chain, err := AnalyzeCallChain("recursive", files, 5)
	if err != nil {
		t.Fatalf("AnalyzeCallChain failed: %v", err)
	}

	expectedChain := CallChain{
		Function: "recursive",
		Callers:  []string{"recursive", "main"},
	}

	if !reflect.DeepEqual(chain, expectedChain) {
		t.Errorf("AnalyzeCallChain() with recursion = %v, want %v", chain, expectedChain)
	}
}
