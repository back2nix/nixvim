package traverser

import (
	"go/ast"
	"io/ioutil"
	"os"
	"testing"

	"github.com/back2nix/go-arg-propagation/pkg/modifier"
	"github.com/back2nix/go-arg-propagation/pkg/parser"
)

func TestASTTraverser_Traverse(t *testing.T) {
	// Создаем временный файл с исходным кодом
	sourceCode := `
package main

func main() {
	result := foo(5)
	println(result)
}

func foo(x int) int {
	return bar(x + 1)
}

func bar(y int) int {
	return y * 2
}
`
	tmpfile, err := ioutil.TempFile("", "test_*.go")
	if err != nil {
		t.Fatalf("Failed to create temp file: %v", err)
	}
	defer os.Remove(tmpfile.Name())

	if _, err := tmpfile.Write([]byte(sourceCode)); err != nil {
		t.Fatalf("Failed to write to temp file: %v", err)
	}
	if err := tmpfile.Close(); err != nil {
		t.Fatalf("Failed to close temp file: %v", err)
	}

	// Инициализируем компоненты
	p := parser.NewParser()
	fdm := modifier.NewFuncDeclModifier()
	flm := modifier.NewFuncLitModifier()
	cem := modifier.NewCallExprModifier([]string{"foo", "bar"})

	traverser := NewASTTraverser(p, fdm, flm, cem)

	// Применяем Traverser
	fileContent, err := ioutil.ReadFile(tmpfile.Name())
	if err != nil {
		t.Fatalf("Failed to read temp file: %v", err)
	}

	astFile, err := p.Parse(fileContent)
	if err != nil {
		t.Fatalf("Failed to parse file: %v", err)
	}

	err = traverser.Traverse(astFile, []string{"foo", "bar"}, "z", "int")
	if err != nil {
		t.Fatalf("Traverse failed: %v", err)
	}

	// Проверяем результаты
	var mainFunc, fooFunc, barFunc *ast.FuncDecl
	for _, decl := range astFile.Decls {
		if funcDecl, ok := decl.(*ast.FuncDecl); ok {
			switch funcDecl.Name.Name {
			case "main":
				mainFunc = funcDecl
			case "foo":
				fooFunc = funcDecl
			case "bar":
				barFunc = funcDecl
			}
		}
	}

	// Проверяем, что аргументы были добавлены
	if !hasParameter(fooFunc, "z", "int") {
		t.Errorf("Parameter 'z int' was not added to foo function")
	}
	if !hasParameter(barFunc, "z", "int") {
		t.Errorf("Parameter 'z int' was not added to bar function")
	}

	// Проверяем, что вызовы функций были изменены
	if mainFunc != nil {
		if !hasFunctionCall(mainFunc.Body, "foo", 2) {
			t.Errorf("Call to foo in main does not have 2 arguments")
		}
	} else {
		t.Errorf("main function not found")
	}

	if fooFunc != nil {
		if !hasFunctionCall(fooFunc.Body, "bar", 2) {
			t.Errorf("Call to bar in foo does not have 2 arguments")
		}
	} else {
		t.Errorf("foo function not found")
	}
}

func hasParameter(funcDecl *ast.FuncDecl, paramName, paramType string) bool {
	if funcDecl == nil || funcDecl.Type.Params == nil {
		return false
	}
	for _, param := range funcDecl.Type.Params.List {
		if len(param.Names) > 0 && param.Names[0].Name == paramName {
			if ident, ok := param.Type.(*ast.Ident); ok && ident.Name == paramType {
				return true
			}
		}
	}
	return false
}

func hasFunctionCall(body *ast.BlockStmt, funcName string, argCount int) bool {
	for _, stmt := range body.List {
		if exprStmt, ok := stmt.(*ast.ExprStmt); ok {
			if callExpr, ok := exprStmt.X.(*ast.CallExpr); ok {
				if ident, ok := callExpr.Fun.(*ast.Ident); ok && ident.Name == funcName {
					return len(callExpr.Args) == argCount
				}
			}
		}
	}
	return false
}
