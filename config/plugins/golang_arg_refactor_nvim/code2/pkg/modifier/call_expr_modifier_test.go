package modifier

import (
	"bytes"
	"go/ast"
	"go/parser"
	"go/printer"
	"go/token"
	"strings"
	"testing"

	"github.com/sergi/go-diff/diffmatchpatch"
)

func TestCallExprModifier_AddArgument(t *testing.T) {
	tests := []struct {
		name              string
		code              string
		functionsToModify []string
		argName           string
		expectedCode      string
	}{
		{
			name: "Don't modify already modified call",
			code: `package main
func main() {
    foo(existingArg)
    foo(anotherArg)
}`,
			functionsToModify: []string{"foo"},
			argName:           "newArg",
			expectedCode: `package main
func main() {
    foo(existingArg, newArg)
    foo(anotherArg, newArg)
}`,
		},
		{
			name: "Modify simple function call",
			code: `package main
func main() {
    foo()
}`,
			functionsToModify: []string{"foo"},
			argName:           "newArg",
			expectedCode: `package main
func main() {
    foo(newArg)
}`,
		},
		{
			name: "Don't modify unrelated function call",
			code: `package main
func main() {
    bar()
}`,
			functionsToModify: []string{"foo"},
			argName:           "newArg",
			expectedCode: `package main
func main() {
    bar()
}`,
		},
		{
			name: "Modify method call",
			code: `package main
func main() {
    obj.Method()
}`,
			functionsToModify: []string{"obj.Method"},
			argName:           "newArg",
			expectedCode: `package main
func main() {
    obj.Method(newArg)
}`,
		},
		{
			name: "Modify variadic function call",
			code: `package main
func main() {
    variadicFunc("a", "b")
}`,
			functionsToModify: []string{"variadicFunc"},
			argName:           "newArg",
			expectedCode: `package main
func main() {
    variadicFunc("a", "b", newArg)
}`,
		},
		{
			name: "Modify multiple calls in one function",
			code: `package main
func main() {
    foo()
    bar()
    foo()
}`,
			functionsToModify: []string{"foo"},
			argName:           "newArg",
			expectedCode: `package main
func main() {
    foo(newArg)
    bar()
    foo(newArg)
}`,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			fset := token.NewFileSet()
			file, err := parser.ParseFile(fset, "", tt.code, parser.ParseComments)
			if err != nil {
				t.Fatalf("Failed to parse code: %v", err)
			}

			modifier := NewCallExprModifier(tt.functionsToModify)

			ast.Inspect(file, func(n ast.Node) bool {
				if callExpr, ok := n.(*ast.CallExpr); ok {
					err := modifier.AddArgument(callExpr, tt.argName)
					if err != nil {
						t.Fatalf("AddArgument failed: %v", err)
					}
				}
				return true
			})

			var buf bytes.Buffer
			err = printer.Fprint(&buf, fset, file)
			if err != nil {
				t.Fatalf("Failed to print modified AST: %v", err)
			}

			got := normalizeWhitespace(buf.String())
			want := normalizeWhitespace(tt.expectedCode)

			if got != want {
				t.Errorf("Modified code does not match expected.\nGot:\n%s\nWant:\n%s\nDiff:\n%s", got, want, diff(want, got))
			}
		})
	}
}

func diff(expected, actual string) string {
	dmp := diffmatchpatch.New()
	diffs := dmp.DiffMain(expected, actual, false)
	return dmp.DiffPrettyText(diffs)
}

// astToString converts an AST to a string representation of the code
func astToString(fset *token.FileSet, node ast.Node) string {
	var buf strings.Builder
	err := printer.Fprint(&buf, fset, node)
	if err != nil {
		return ""
	}
	return buf.String()
}

// normalizeWhitespace removes leading and trailing whitespace from each line,
// ensures consistent newline characters, and trims the final newline
func normalizeWhitespace(s string) string {
	lines := strings.Split(s, "\n")
	var result []string
	for _, line := range lines {
		trimmed := strings.TrimSpace(line)
		if trimmed != "" {
			result = append(result, trimmed)
		}
	}
	return strings.Join(result, "\n")
}
