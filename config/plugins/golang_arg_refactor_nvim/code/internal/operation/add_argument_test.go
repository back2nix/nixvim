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
	result := outerFunction(10, 20, z)
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

func add(x, y int, z int) int {
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

func main(z int) {
        result := outerFunction(10, 20, z)
        fmt.Println("Result:", result)
}
func outerFunction(a, b int, z int) int {
        return middleFunction(a, b, func(x, y int, z int) int {
                return innerFunction(x, y, z)
        }, z)
}
func middleFunction(a, b int, operation func(int, int, z int) int, z int) int {
        return operation(a, b, z)
}
func innerFunction(x, y int, z int) int {
        return add(x, y, z)
}
func add(x, y int, z int) int {
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
	return &Calculator{cache: make(map[string]int)}
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
	case "complexAdd":
		result = c.complexOperationAdd(a, b, func(x, y int) int { return c.add(x, y) })
	case "complexAdd2":
		result = c.complexOperationAdd2(a, b, func(x, y int) int { return x + y })
	default:
		result = c.complexOperation(a, b, func(x, y int) int { return x + y })
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

func (c *Calculator) complexOperationAdd2(a, b int, op func(int, int) int) int {
	return c.add(a, b)
}

func (c *Calculator) complexOperationAdd(a, b int, op func(int, int) int) int {
	return op(a, b)
}

func (c *Calculator) complexOperation(a, b int, op func(int, int) int) int {
	return op(a, b)
}

func main() {
	calc := NewCalculator()
	result := calc.Calculate("complexAdd2", 10, 20)
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

func NewCalculator() *Calculator {
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
		result = c.multiply(a, b)
	case "complexAdd":
		result = c.complexOperationAdd(a, b, func(x, y int) int { return c.add(x, y, z) })
	case "complexAdd2":
		result = c.complexOperationAdd2(a, b, func(x, y, z int) int { return x + y }, z)
	default:
		result = c.complexOperation(a, b, z, func(x, y, z int) int { return x + y })
	}
	c.cache[key] = result
	return result
}

func (c *Calculator) add(x, y int, z int) int {
	return x + y
}

func (c *Calculator) multiply(x, y int) int {
	return x * y
}

func (c *Calculator) complexOperationAdd2(a, b int, op func(int, int, int) int, z int) int {
	return c.add(a, b, z)
}

func (c *Calculator) complexOperationAdd(a, b int, op func(int, int) int) int {
	return op(a, b)
}

func (c *Calculator) complexOperation(a, b, z int, op func(int, int, int) int) int {
	return op(a, b, z)
}

func main() {
	calc := NewCalculator()
	result := calc.Calculate("complexAdd2", 10, 20, 0)
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
