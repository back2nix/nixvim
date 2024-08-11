package ast

import (
	"fmt"
	"go/ast"
	"go/parser"
	"go/token"
)

// FunctionInfo represents the extracted information from a function declaration
type FunctionInfo struct {
	Name       string
	Parameters []*ast.Field
	Results    []*ast.Field
}

// ParseFile parses a Go file and returns its AST
func ParseFile(filename string) (*ast.File, error) {
	fset := token.NewFileSet()
	node, err := parser.ParseFile(fset, filename, nil, parser.ParseComments)
	if err != nil {
		return nil, fmt.Errorf("failed to parse file: %w", err)
	}
	return node, nil
}

// FindFunctions traverses the AST and returns all function declarations
func FindFunctions(node *ast.File) []*ast.FuncDecl {
	var functions []*ast.FuncDecl
	ast.Inspect(node, func(n ast.Node) bool {
		if fn, ok := n.(*ast.FuncDecl); ok {
			functions = append(functions, fn)
		}
		return true
	})
	return functions
}

// ExtractFunctionInfo extracts relevant information from a function declaration
func ExtractFunctionInfo(funcDecl *ast.FuncDecl) FunctionInfo {
	info := FunctionInfo{
		Name:       funcDecl.Name.Name,
		Parameters: funcDecl.Type.Params.List,
	}
	if funcDecl.Type.Results != nil {
		info.Results = funcDecl.Type.Results.List
	}
	return info
}

// ParseGoFile parses a Go file and returns information about all functions
func ParseGoFile(filename string) ([]FunctionInfo, error) {
	node, err := ParseFile(filename)
	if err != nil {
		return nil, err
	}

	functions := FindFunctions(node)
	var functionInfos []FunctionInfo
	for _, fn := range functions {
		functionInfos = append(functionInfos, ExtractFunctionInfo(fn))
	}

	return functionInfos, nil
}
