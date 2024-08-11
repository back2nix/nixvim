package ast

import (
	"bytes"
	"fmt"
	"go/ast"
	"go/format"
	"go/token"
	"io/ioutil"
)

func ModifyFunction(file *ast.File, funcName string, argName string, argType string, isAdding bool) error {
	ast.Inspect(file, func(n ast.Node) bool {
		switch node := n.(type) {
		case *ast.FuncDecl:
			if isAdding {
				addArgumentToFunction(node, argName, argType)
			} else {
				removeArgumentFromFunction(node, argName)
			}
		case *ast.FuncLit:
			if isAdding {
				addArgumentToFuncLit(node, argName, argType)
			} else {
				removeArgumentFromFuncLit(node, argName)
			}
		}
		return true
	})

	UpdateFunctionCalls(file, argName, argType, isAdding)
	return nil
}

func addArgumentToFunction(fn *ast.FuncDecl, argName, argType string) {
	newField := &ast.Field{
		Names: []*ast.Ident{ast.NewIdent(argName)},
		Type:  ast.NewIdent(argType),
	}

	for _, field := range fn.Type.Params.List {
		for _, name := range field.Names {
			if name.Name == argName {
				return // Argument already exists
			}
		}
	}

	fn.Type.Params.List = append(fn.Type.Params.List, newField)
	updateFunctionBody(fn.Body, argName)
}

func removeArgumentFromFunction(fn *ast.FuncDecl, argName string) {
	for i, field := range fn.Type.Params.List {
		for j, name := range field.Names {
			if name.Name == argName {
				field.Names = append(field.Names[:j], field.Names[j+1:]...)
				if len(field.Names) == 0 {
					fn.Type.Params.List = append(fn.Type.Params.List[:i], fn.Type.Params.List[i+1:]...)
				}
				return
			}
		}
	}
}

func addArgumentToFuncLit(fn *ast.FuncLit, argName, argType string) {
	newField := &ast.Field{
		Names: []*ast.Ident{ast.NewIdent(argName)},
		Type:  ast.NewIdent(argType),
	}

	for _, field := range fn.Type.Params.List {
		for _, name := range field.Names {
			if name.Name == argName {
				return // Argument already exists
			}
		}
	}

	fn.Type.Params.List = append(fn.Type.Params.List, newField)
	updateFunctionBody(fn.Body, argName)
}

func removeArgumentFromFuncLit(fn *ast.FuncLit, argName string) {
	for i, field := range fn.Type.Params.List {
		for j, name := range field.Names {
			if name.Name == argName {
				field.Names = append(field.Names[:j], field.Names[j+1:]...)
				if len(field.Names) == 0 {
					fn.Type.Params.List = append(fn.Type.Params.List[:i], fn.Type.Params.List[i+1:]...)
				}
				return
			}
		}
	}
}

func updateFunctionBody(body *ast.BlockStmt, argName string) {
	ast.Inspect(body, func(n ast.Node) bool {
		switch node := n.(type) {
		case *ast.CallExpr:
			updateCall(node, argName, true)
		}
		return true
	})
}

func UpdateFunctionCalls(file *ast.File, argName string, argType string, isAdding bool) {
	ast.Inspect(file, func(n ast.Node) bool {
		switch node := n.(type) {
		case *ast.CallExpr:
			updateCall(node, argName, isAdding)
		case *ast.FuncLit:
			if isAdding {
				addArgumentToFuncLit(node, argName, argType)
			} else {
				removeArgumentFromFuncLit(node, argName)
			}
		}
		return true
	})
}

func updateCall(call *ast.CallExpr, argName string, isAdding bool) {
	if isAdding {
		for _, arg := range call.Args {
			if ident, ok := arg.(*ast.Ident); ok && ident.Name == argName {
				return // Argument already exists in the call
			}
		}
		call.Args = append(call.Args, &ast.Ident{Name: argName})
	} else {
		for i, arg := range call.Args {
			if ident, ok := arg.(*ast.Ident); ok && ident.Name == argName {
				call.Args = append(call.Args[:i], call.Args[i+1:]...)
				break
			}
		}
	}

	// Update function types in arguments
	for _, arg := range call.Args {
		if funcLit, ok := arg.(*ast.FuncLit); ok {
			if isAdding {
				addArgumentToFuncLit(funcLit, argName, "int") // Assuming int type for simplicity
			} else {
				removeArgumentFromFuncLit(funcLit, argName)
			}
		}
	}
}

func WriteModifiedAST(file *ast.File, filename string) error {
	var buf bytes.Buffer
	if err := format.Node(&buf, token.NewFileSet(), file); err != nil {
		return fmt.Errorf("failed to format AST: %w", err)
	}

	if err := ioutil.WriteFile(filename, buf.Bytes(), 0o644); err != nil {
		return fmt.Errorf("failed to write to file: %w", err)
	}

	return nil
}
