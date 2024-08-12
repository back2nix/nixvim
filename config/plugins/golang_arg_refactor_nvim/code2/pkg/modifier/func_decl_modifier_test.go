package modifier

import (
	"fmt"
	"go/ast"
	"go/parser"
	"go/token"
	"strings"
	"testing"
)

func TestFuncDeclModifier_AddParameter(t *testing.T) {
	tests := []struct {
		name     string
		input    string
		expected string
	}{
		{
			name:     "Add parameter to function with no parameters",
			input:    "func test() {}",
			expected: "func test(newParam int) {}",
		},
		{
			name:     "Add parameter to function with existing parameters",
			input:    "func test(a string) {}",
			expected: "func test(a string, newParam int) {}",
		},
		{
			name:     "Add parameter to variadic function",
			input:    "func test(a ...string) {}",
			expected: "func test(newParam int, a ...string) {}",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			fset := token.NewFileSet()
			node, err := parser.ParseFile(fset, "", "package main\n"+tt.input, parser.ParseComments)
			if err != nil {
				t.Fatalf("Failed to parse input: %v", err)
			}

			funcDecl := node.Decls[0].(*ast.FuncDecl)
			modifier := NewFuncDeclModifier()
			modifier.AddParameter(funcDecl, "newParam", "int")

			got := formatFuncDecl(funcDecl)
			if got != tt.expected {
				t.Errorf("AddParameter() =\n%v\nwant:\n%v", got, tt.expected)
			}
		})
	}
}

func formatFuncDecl(funcDecl *ast.FuncDecl) string {
	var params []string
	for _, p := range funcDecl.Type.Params.List {
		param := ""
		if len(p.Names) > 0 {
			param += p.Names[0].Name + " "
		}
		switch t := p.Type.(type) {
		case *ast.Ident:
			param += t.Name
		case *ast.Ellipsis:
			param += "..." + t.Elt.(*ast.Ident).Name
		}
		params = append(params, param)
	}

	return fmt.Sprintf("func %s(%s) {}", funcDecl.Name.Name, strings.Join(params, ", "))
}
