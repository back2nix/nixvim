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

func updateFuncType(funcType *ast.FuncType, argName, argType string, isAdding bool) {
	if isAdding {
		// Проверяем, существует ли уже аргумент
		for _, field := range funcType.Params.List {
			for _, name := range field.Names {
				if name.Name == argName {
					return // Аргумент уже существует
				}
			}
			// Проверяем и обновляем вложенные функциональные типы
			if fType, ok := field.Type.(*ast.FuncType); ok {
				updateFuncType(fType, argName, argType, isAdding)
			}
		}
		newField := &ast.Field{
			Names: []*ast.Ident{ast.NewIdent(argName)},
			Type:  ast.NewIdent(argType),
		}
		funcType.Params.List = append(funcType.Params.List, newField)
	} else {
		// Логика удаления остается прежней, но добавляем рекурсивное обновление
		for _, field := range funcType.Params.List {
			if fType, ok := field.Type.(*ast.FuncType); ok {
				updateFuncType(fType, argName, argType, isAdding)
			}
		}
	}
}

func addArgumentToFunction(fn *ast.FuncDecl, argName, argType string) {
	updateFuncType(fn.Type, argName, argType, true)
	updateFunctionBody(fn.Body, argName, argType)
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
	updateFunctionBody(fn.Body, argName, argType)
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

func updateFunctionBody(body *ast.BlockStmt, argName string, argType string) {
	ast.Inspect(body, func(n ast.Node) bool {
		switch node := n.(type) {
		case *ast.CallExpr:
			updateCall(node, argName, argType, true)
		}
		return true
	})
}

func UpdateFunctionCalls(file *ast.File, argName string, argType string, isAdding bool) {
	ast.Inspect(file, func(n ast.Node) bool {
		switch node := n.(type) {
		case *ast.CallExpr:
			updateCall(node, argName, argType, isAdding)
		case *ast.FuncLit:
			updateFuncType(node.Type, argName, argType, isAdding)
		}
		return true
	})
}

func updateCall(call *ast.CallExpr, argName string, argType string, isAdding bool) {
	if shouldUpdateCall(call) {
		if isAdding {
			// Проверяем, существует ли уже аргумент
			for _, arg := range call.Args {
				if ident, ok := arg.(*ast.Ident); ok && ident.Name == argName {
					return // Аргумент уже существует в вызове
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
	}

	// Обновляем типы функциональных аргументов
	for i, arg := range call.Args {
		switch argNode := arg.(type) {
		case *ast.FuncLit:
			updateFuncType(argNode.Type, argName, argType, isAdding)
		case *ast.Ident:
			if argNode.Obj != nil && argNode.Obj.Decl != nil {
				switch decl := argNode.Obj.Decl.(type) {
				case *ast.FuncDecl:
					updateFuncType(decl.Type, argName, argType, isAdding)
				case *ast.Field:
					if funcType, ok := decl.Type.(*ast.FuncType); ok {
						updateFuncType(funcType, argName, argType, isAdding)
					}
				}
			}
		}
		// Обновляем тип аргумента в вызове, если это функциональный тип
		if funcType, ok := call.Args[i].(*ast.FuncLit); ok {
			updateFuncType(funcType.Type, argName, argType, isAdding)
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

func shouldUpdateCall(call *ast.CallExpr) bool {
	if selExpr, ok := call.Fun.(*ast.SelectorExpr); ok {
		if ident, ok := selExpr.X.(*ast.Ident); ok {
			// Не обновляем вызовы fmt.Println и подобные
			return ident.Name != "fmt"
		}
	}
	return true
}
