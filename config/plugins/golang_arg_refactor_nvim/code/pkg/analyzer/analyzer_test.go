package analyzer

import (
	"fmt"
	"strings"
	"testing"
)

func TestAnalyzeCallChain(t *testing.T) {
	src := `
package main

func main() {
	foo()
}

func foo() {
	bar()
	func() {
		func() {
			baz()
		}()
	}()
}

func bar() {
	// Пустая функция
}

func baz() {
	// Целевая функция
}

func unused() {
	// Эта функция не должна попасть в цепочку вызовов
}
`

	analyzer := NewCallChainAnalyzer()
	chain, err := analyzer.AnalyzeCallChain([]byte(src), "baz")
	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}

	// Проверяем, что цепочка содержит ожидаемые элементы в правильном порядке
	expected := []string{"foo", "anonymous", "anonymous", "baz"}
	fmt.Printf("Expected chain length %v, but got %v\n", chain, expected)
	if len(chain) != len(expected) {
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
