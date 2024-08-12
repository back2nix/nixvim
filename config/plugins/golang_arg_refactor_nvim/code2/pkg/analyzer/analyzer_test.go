package analyzer

import (
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
	expected := []string{"baz", "foo", "main", "anonymous", "anonymous"}
	if len(chain) != len(expected) {
		t.Errorf("Expected chain length %d, but got %d\n%v -> %v", len(expected), len(chain), expected, chain)
	} else {
		for i, funcName := range chain {
			if !strings.HasPrefix(funcName, expected[i]) {
				t.Errorf("At position expected %s, but got %s", expected, chain)
				break
			}
		}
	}
}
