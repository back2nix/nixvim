package operation_test

import (
	"io/ioutil"
	"os"
	"path/filepath"
	"testing"

	"github.com/back2nix/golang_arg_refactor_nvim/internal/operation"
)

func TestAddArgumentVeryComplex(t *testing.T) {
	tempDir, err := ioutil.TempDir("", "addargument_very_complex_test")
	if err != nil {
		t.Fatalf("Failed to create temp directory: %v", err)
	}
	defer os.RemoveAll(tempDir)

	testFile := `package main

import (
	"fmt"
	"sync"
)

type Calculator struct {
	cache map[string]int
	mu    sync.Mutex
}

func NewCalculator() *Calculator {
	return &Calculator{
		cache: make(map[string]int),
	}
}

func (c *Calculator) Calculate(operation string, a, b int) int {
	c.mu.Lock()
	defer c.mu.Unlock()

	key := fmt.Sprintf("%s:%d:%d", operation, a, b)
	if result, ok := c.cache[key]; ok {
		return result
	}

	var result int
	switch operation {
	case "add":
		result = c.add(a, b)
	case "multiply":
		result = c.multiply(a, b)
	default:
          result = c.complexOperation(a, b, func(x, y int, z int) int {
          }, z)
	}

	c.cache[key] = result
	return result
}

func (c *Calculator) add(x, y int) int {
	return x + y
}

func (c *Calculator) multiply(x, y int) int {
	return x * y
}

func (c *Calculator) complexOperation(a, b int, op func(int, int) int) int {
	return op(a, b)
}

func main() {
	calc := NewCalculator()
	result := calc.Calculate("add", 10, 20)
	fmt.Println("Result:", result)
}
`

	filePath := filepath.Join(tempDir, "main.go")
	err = ioutil.WriteFile(filePath, []byte(testFile), 0o644)
	if err != nil {
		t.Fatalf("Failed to write test file: %v", err)
	}

	req := operation.AddArgumentRequest{
		TargetFunc: "add",
		ArgName:    "z",
		ArgType:    "int",
		MaxDepth:   10,
	}

	err = operation.AddArgument(req, []string{filePath})
	if err != nil {
		t.Fatalf("AddArgument failed: %v", err)
	}

	modifiedContent, err := ioutil.ReadFile(filePath)
	if err != nil {
		t.Fatalf("Failed to read modified file: %v", err)
	}

	expectedContent := `package main

import (
	"fmt"
	"sync"
)

type Calculator struct {
	cache map[string]int
	mu    sync.Mutex
}

func NewCalculator(z int) *Calculator {
	return &Calculator{cache: make(map[string]int)}
}
func (c *Calculator) Calculate(operation string, a, b int, z int) int {
	c.mu.Lock()
	defer c.mu.Unlock()
	key := fmt.Sprintf("%s:%d:%d", operation, a, b)
	if result, ok := c.cache[key]; ok {
		return result
	}
	var result int
	switch operation {
	case "add":
		result = c.add(a, b, z)
	case "multiply":
		result = c.multiply(a, b, z)
	default:
		result = c.complexOperation(a, b, func(x, y int, z int) int {
		}, z)
	}
	c.cache[key] = result
	return result
}
func (c *Calculator) add(x, y int, z int) int {
	return x + y
}
func (c *Calculator) multiply(x, y int, z int) int {
	return x * y
}
func (c *Calculator) complexOperation(a, b int, op func(int, int, z int) int, z int) int {
	return op(a, b, z)
}
func main(z int) {
	calc := NewCalculator(z)
	result := calc.Calculate("add", 10, 20, z)
	fmt.Println("Result:", result)
}
`

	if string(modifiedContent) != expectedContent {
		t.Errorf("Modified content does not match expected content.\nGot:\n%s\nWant:\n%s",
			string(modifiedContent),
			expectedContent,
		)
	}
}
