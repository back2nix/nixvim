package analyzer

import (
	"go/token"
	"strings"
	"testing"
)

func TestAnalyzeCallChain(t *testing.T) {
	src := `
package main

import (
	"fmt"
)

type MyStruct struct {
	value int
}

func (m *MyStruct) Method1(callback func() int) {
	result := callback()
	fmt.Printf("Method1 called with result: %d\n", result)
	m.Method2(func() {
		fmt.Println("Anonymous function in Method2")
	})
}

func (m *MyStruct) Method2(callback func()) {
	fmt.Println("Method2 called")
	callback()
	m.value++
}

func outerFunction(x int) func(int) int {
	return func(y int) int {
		return x + y
	}
}

func main() {
	myStruct := &MyStruct{value: 10}

	myStruct.Method1(func() int {
		innerFunc := outerFunction(5)
		return innerFunc(3)
	})

	fmt.Printf("MyStruct value: %d\n", myStruct.value)

	func() {
		fmt.Println("Anonymous function in main")
		func() {
			fmt.Println("Nested anonymous function")
			myStruct.Method2(func() {
				fmt.Printf("Final value: %d\n", myStruct.value)
			})
		}()
	}()
}
`

	fset := token.NewFileSet()
	analyzer := NewCallChainAnalyzer(fset)
	chain, err := analyzer.AnalyzeCallChain([]byte(src), "callback")
	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}

	// Check if the chain contains the expected elements in the correct order
	expected := []string{"foo", "anonymous", "anonymous", "baz"}
	if len(chain) != len(expected) {
		t.Errorf("Expected chain length %+v, but got %+v", expected, chain)
		t.Errorf("Expected chain length %d, but got %d", len(expected), len(chain))
	} else {
		for i, funcName := range chain {
			if expected[i] == "anonymous" {
				if !strings.HasPrefix(funcName, "anonymous") {
					t.Errorf("At position %d, expected anonymous function, but got %s", i, funcName)
				}
			} else if funcName != expected[i] {
				t.Errorf("At position %d, expected %s, but got %s", i, expected[i], funcName)
			}
		}
	}
}
