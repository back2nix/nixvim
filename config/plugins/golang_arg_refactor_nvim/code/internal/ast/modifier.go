package ast

import (
	"bytes"
	"fmt"
	"go/ast"
	"go/format"
	"go/token"
	"io/ioutil"
)

// ModifyFunction adds or removes an argument from a function declaration
func ModifyFunction(file *ast.File, funcName string, argName string, argType string, isAdding bool) error {
	var targetFunc *ast.FuncDecl
	ast.Inspect(file, func(n ast.Node) bool {
		if fn, ok := n.(*ast.FuncDecl); ok && fn.Name.Name == funcName {
			targetFunc = fn
			return false
		}
		return true
	})

	if targetFunc == nil {
		return fmt.Errorf("function %s not found", funcName)
	}

	if isAdding {
		return addArgument(targetFunc, argName, argType)
	}
	return removeArgument(targetFunc, argName)
}

func addArgument(fn *ast.FuncDecl, argName, argType string) error {
	newField := &ast.Field{
		Names: []*ast.Ident{ast.NewIdent(argName)},
		Type:  ast.NewIdent(argType),
	}

	if len(fn.Type.Params.List) > 0 {
		lastParam := fn.Type.Params.List[len(fn.Type.Params.List)-1]
		if lastIdent, ok := lastParam.Type.(*ast.Ident); ok && lastIdent.Name == argType {
			// If the last parameter is of the same type, just add the new name
			lastParam.Names = append(lastParam.Names, ast.NewIdent(argName))
		} else {
			// Otherwise, add a new field
			fn.Type.Params.List = append(fn.Type.Params.List, newField)
		}
	} else {
		fn.Type.Params.List = append(fn.Type.Params.List, newField)
	}

	return nil
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

func removeArgument(fn *ast.FuncDecl, argName string) error {
	for i, field := range fn.Type.Params.List {
		for _, name := range field.Names {
			if name.Name == argName {
				fn.Type.Params.List = append(fn.Type.Params.List[:i], fn.Type.Params.List[i+1:]...)
				return nil
			}
		}
	}
	return fmt.Errorf("argument %s not found in function %s", argName, fn.Name.Name)
}

func UpdateFunctionCalls(file *ast.File, funcName string, argName string, argType string, isAdding bool) {
	ast.Inspect(file, func(n ast.Node) bool {
		switch node := n.(type) {
		case *ast.CallExpr:
			if ident, ok := node.Fun.(*ast.Ident); ok && ident.Name == funcName {
				if isAdding {
					newArg := &ast.Ident{Name: argName}
					node.Args = append(node.Args, newArg)
				} else {
					// Removal logic
					for i, arg := range node.Args {
						if ident, ok := arg.(*ast.Ident); ok && ident.Name == argName {
							node.Args = append(node.Args[:i], node.Args[i+1:]...)
							break
						}
					}
				}
			}

			// Update arguments of nested calls
			for i, arg := range node.Args {
				if call, ok := arg.(*ast.CallExpr); ok {
					if funIdent, ok := call.Fun.(*ast.Ident); ok {
						UpdateFunctionCalls(file, funIdent.Name, argName, argType, isAdding)
						// If we're adding and this is a relevant function, update this argument
						if isAdding && (funIdent.Name == funcName || containsRelevantCall(call, funcName)) {
							node.Args[i] = &ast.CallExpr{
								Fun:  call.Fun,
								Args: append(call.Args, &ast.Ident{Name: argName}),
							}
						}
					}
				}
			}
		}
		return true
	})
}

// Helper function to check if a call expression contains a relevant function call
func containsRelevantCall(expr ast.Expr, funcName string) bool {
	relevant := false
	ast.Inspect(expr, func(n ast.Node) bool {
		if call, ok := n.(*ast.CallExpr); ok {
			if ident, ok := call.Fun.(*ast.Ident); ok && ident.Name == funcName {
				relevant = true
				return false
			}
		}
		return true
	})
	return relevant
}
