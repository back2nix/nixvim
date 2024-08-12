package modifier

import (
	"go/ast"
	"go/parser"
	"go/printer"
	"go/token"
	"strings"
	"testing"
)

func TestFuncLitModifier_AddParameter(t *testing.T) {
	modifier := NewFuncLitModifier()

	tests := []struct {
		name        string
		input       string
		paramName   string
		paramType   string
		expected    string
		expectError bool
	}{
		{
			name:      "Add parameter to empty function",
			input:     "func() {}",
			paramName: "x",
			paramType: "int",
			expected:  "func(x int) {}",
		},
		{
			name:      "Add parameter to function with existing parameters",
			input:     "func(a string) {}",
			paramName: "x",
			paramType: "int",
			expected:  "func(a string, x int) {}",
		},
		{
			name:      "Add duplicate parameter (no change)",
			input:     "func(x int) {}",
			paramName: "x",
			paramType: "int",
			expected:  "func(x int) {}",
		},
		{
			name:        "Invalid input - nil FuncLit",
			input:       "",
			paramName:   "x",
			paramType:   "int",
			expectError: true,
		},
		{
			name:        "Invalid input - empty parameter name",
			input:       "func() {}",
			paramName:   "",
			paramType:   "int",
			expectError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			var funcLit *ast.FuncLit
			if tt.input != "" {
				expr, _ := parser.ParseExpr(tt.input)
				funcLit = expr.(*ast.FuncLit)
			}

			err := modifier.AddParameter(funcLit, tt.paramName, tt.paramType)

			if tt.expectError {
				if err == nil {
					t.Errorf("Expected an error, but got nil")
				}
			} else {
				if err != nil {
					t.Errorf("Unexpected error: %v", err)
				}

				result := exprToString(funcLit)
				if result != tt.expected {
					t.Errorf("Expected %q, but got %q", tt.expected, result)
				}
			}
		})
	}
}

// exprToString converts an AST expression to a string, removing newlines within function bodies
func exprToString(expr ast.Expr) string {
	if expr == nil {
		return ""
	}

	var buf strings.Builder
	fset := token.NewFileSet()

	err := printer.Fprint(&buf, fset, expr)
	if err != nil {
		return ""
	}

	// Remove newlines within function bodies
	result := buf.String()
	result = strings.ReplaceAll(result, "{\n}", "{}")
	result = strings.ReplaceAll(result, "{ }", "{}")

	return result
}

// Additional helper function to parse a string into an AST expression
func parseExpr(s string) (ast.Expr, error) {
	return parser.ParseExpr(s)
}
