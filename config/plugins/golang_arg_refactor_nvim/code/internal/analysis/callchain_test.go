package analysis

import (
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"reflect"
	"testing"
)

func TestImprovedAnalyzeCallChain(t *testing.T) {
	tempDir, err := ioutil.TempDir("", "test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	// Test file contents
	files := map[string]string{
		"main.go": `
package main

import "example.com/mypackage"

func main() {
	foo()
	mypackage.ExternalFunc()
	c := &MyStruct{}
	c.Method()
}

func foo() {
	bar()
}

func bar() {
	baz()
}

func baz() {}

type MyStruct struct{}

func (m *MyStruct) Method() {
	foo()
}

func (m *MyStruct) AnotherMethod() {
	m.Method()
}

func higherOrder(f func()) {
	f()
}

func withAnonymous() {
	func() {
		foo()
	}()
}

func withGoroutine() {
	go foo()
}
`,
		"nested.go": `
package main

func outer() {
	inner := func() {
		foo()
	}
	inner()
}
`,
		"recursive.go": `
package main

func recursiveA(n int) {
	if n > 0 {
		recursiveB(n - 1)
	}
}

func recursiveB(n int) {
	if n > 0 {
		recursiveA(n - 1)
	}
}
`,
		"mypackage/external.go": `
package mypackage

func ExternalFunc() {
	InternalFunc()
}

func InternalFunc() {}
`,
	}

	// Write test files
	for filename, content := range files {
		fullPath := filepath.Join(tempDir, filename)
		err := os.MkdirAll(filepath.Dir(fullPath), 0o755)
		if err != nil {
			t.Fatalf("Failed to create directory: %v", err)
		}
		err = ioutil.WriteFile(fullPath, []byte(content), 0o644)
		if err != nil {
			t.Fatalf("Failed to write file %s: %v", filename, err)
		}
	}

	allFiles, err := GetAllGoFiles(tempDir)
	if err != nil {
		t.Fatalf("Failed to get Go files: %v", err)
	}

	testCases := []struct {
		name          string
		targetFunc    string
		expectedChain CallChain
		maxDepth      int
	}{
		{
			name:       "Cross-package call",
			targetFunc: "InternalFunc",
			expectedChain: CallChain{
				Function: "InternalFunc",
				Callers:  []string{"ExternalFunc", "main"},
			},
			maxDepth: 5,
		},
		// {
		// 	name:       "Nested function call",
		// 	targetFunc: "foo",
		// 	expectedChain: CallChain{
		// 		Function: "foo",
		// 		Callers:  []string{"bar", "Method", "main", "inner"},
		// 	},
		// 	maxDepth: 5,
		// },
		// {
		// 	name:       "Anonymous function call",
		// 	targetFunc: "foo",
		// 	expectedChain: CallChain{
		// 		Function: "foo",
		// 		Callers:  []string{"bar", "Method", "main", "inner"},
		// 	},
		// 	maxDepth: 5,
		// },
		// {
		// 	name:       "Indirect recursion",
		// 	targetFunc: "recursiveA",
		// 	expectedChain: CallChain{
		// 		Function: "recursiveA",
		// 		Callers:  []string{"recursiveB"},
		// 	},
		// 	maxDepth: 5,
		// },
		{
			name:       "Method call through variable",
			targetFunc: "Method",
			expectedChain: CallChain{
				Function: "Method",
				Callers:  []string{"main", "MyStruct.AnotherMethod"},
			},
			maxDepth: 5,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			chain, err := AnalyzeCallChain(tc.targetFunc, allFiles, tc.maxDepth)
			if err != nil {
				t.Fatalf("AnalyzeCallChain failed: %v", err)
			}

			if !reflect.DeepEqual(chain, tc.expectedChain) {
				t.Errorf("AnalyzeCallChain() = %v, want %v", chain, tc.expectedChain)
			}
		})
	}
}

func BenchmarkAnalyzeCallChain(b *testing.B) {
	// Create a larger project structure for benchmarking
	tempDir, err := ioutil.TempDir("", "benchmark")
	if err != nil {
		b.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	// Create 100 Go files with dummy content
	for i := 0; i < 100; i++ {
		filename := filepath.Join(tempDir, fmt.Sprintf("file%d.go", i))
		content := fmt.Sprintf(`
package main

func func%d() {
	func%d()
}
`, i, (i+1)%100)
		if err := ioutil.WriteFile(filename, []byte(content), 0o644); err != nil {
			b.Fatalf("Failed to write benchmark file: %v", err)
		}
	}

	files, err := GetAllGoFiles(tempDir)
	if err != nil {
		b.Fatalf("Failed to get Go files: %v", err)
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, err := AnalyzeCallChain("func0", files, 10)
		if err != nil {
			b.Fatalf("AnalyzeCallChain failed: %v", err)
		}
	}
}
