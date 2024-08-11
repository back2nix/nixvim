package ast_test

import (
	stdAst "go/ast"
	"go/parser"
	"go/token"
	"os"
	"testing"

	"github.com/back2nix/golang_arg_refactor_nvim/internal/ast"
)

func TestASTModifier(t *testing.T) {
	// Step 1: Create a test Go file
	testCode := `
package main

func testFunction(a int) int {
	return a
}

var testVar = func(b string) string {
	return b
}
`

	// Parse the test code
	fset := token.NewFileSet()
	file, err := parser.ParseFile(fset, "", testCode, 0)
	if err != nil {
		t.Fatalf("Failed to parse test code: %v", err)
	}

	// Step 2: Test creating a new ASTModifier
	modifier := ast.NewASTModifier(file, "testFunction", "newArg", "string", true)
	if modifier == nil {
		t.Fatal("Failed to create ASTModifier")
	}

	// Step 3: Test adding an argument to the function
	err = modifier.ModifyFunction()
	if err != nil {
		t.Fatalf("Failed to modify function: %v", err)
	}

	// Check if the argument was added
	stdAst.Inspect(file, func(n stdAst.Node) bool {
		if funcDecl, ok := n.(*stdAst.FuncDecl); ok && funcDecl.Name.Name == "testFunction" {
			if len(funcDecl.Type.Params.List) != 2 {
				t.Errorf("Expected 2 parameters, got %d", len(funcDecl.Type.Params.List))
			}
		}
		return true
	})

	// Step 4: Test removing an argument from the function
	modifier = ast.NewASTModifier(file, "testFunction", "newArg", "string", false)
	err = modifier.ModifyFunction()
	if err != nil {
		t.Fatalf("Failed to modify function: %v", err)
	}

	// Check if the argument was removed
	stdAst.Inspect(file, func(n stdAst.Node) bool {
		if funcDecl, ok := n.(*stdAst.FuncDecl); ok && funcDecl.Name.Name == "testFunction" {
			if len(funcDecl.Type.Params.List) != 1 {
				t.Errorf("Expected 1 parameter, got %d", len(funcDecl.Type.Params.List))
			}
		}
		return true
	})

	// Step 5: Test modifying function literal
	modifier = ast.NewASTModifier(file, "testVar", "newArg", "int", true)
	err = modifier.ModifyFunction()
	if err != nil {
		t.Fatalf("Failed to modify function literal: %v", err)
	}

	// Check if the argument was added to the function literal
	stdAst.Inspect(file, func(n stdAst.Node) bool {
		if funcLit, ok := n.(*stdAst.FuncLit); ok {
			if len(funcLit.Type.Params.List) != 2 {
				t.Errorf("Expected 2 parameters in function literal, got %d", len(funcLit.Type.Params.List))
			}
		}
		return true
	})

	// Step 6: Test writing modified AST to file
	tempFile, err := os.CreateTemp("", "test_ast_*.go")
	if err != nil {
		t.Fatalf("Failed to create temp file: %v", err)
	}
	defer os.Remove(tempFile.Name())

	err = modifier.WriteModifiedAST(tempFile.Name())
	if err != nil {
		t.Fatalf("Failed to write modified AST to file: %v", err)
	}

	// Check if the file was created and contains content
	fileInfo, err := os.Stat(tempFile.Name())
	if err != nil {
		t.Fatalf("Failed to get file info: %v", err)
	}
	if fileInfo.Size() == 0 {
		t.Error("Written file is empty")
	}
}
