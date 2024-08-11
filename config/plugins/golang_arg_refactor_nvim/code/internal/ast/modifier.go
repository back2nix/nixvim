package ast

import (
	"bytes"
	"fmt"
	"go/ast"
	"go/format"
	"go/token"
	"io/ioutil"
)

type ASTModifier struct {
	File     *ast.File
	FuncName string
	ArgName  string
	ArgType  string
	IsAdding bool
}

func NewASTModifier(file *ast.File, funcName, argName, argType string, isAdding bool) *ASTModifier {
	return &ASTModifier{
		File:     file,
		FuncName: funcName,
		ArgName:  argName,
		ArgType:  argType,
		IsAdding: isAdding,
	}
}

func (m *ASTModifier) ModifyFunction() error {
	ast.Inspect(m.File, func(n ast.Node) bool {
		switch node := n.(type) {
		case *ast.FuncDecl:
			if m.IsAdding {
				m.addArgumentToFunction(node)
			} else {
				m.removeArgumentFromFunction(node)
			}
		case *ast.FuncLit:
			if m.IsAdding {
				m.addArgumentToFuncLit(node)
			} else {
				m.removeArgumentFromFuncLit(node)
			}
		}
		return true
	})

	m.UpdateFunctionCalls()
	return nil
}

func (m *ASTModifier) updateFuncType(funcType *ast.FuncType) {
	if m.IsAdding {
		for _, field := range funcType.Params.List {
			for _, name := range field.Names {
				if name.Name == m.ArgName {
					return // Аргумент уже существует
				}
			}
			if fType, ok := field.Type.(*ast.FuncType); ok {
				m.updateFuncType(fType)
			}
		}
		newField := &ast.Field{
			Names: []*ast.Ident{ast.NewIdent(m.ArgName)},
			Type:  ast.NewIdent(m.ArgType),
		}
		funcType.Params.List = append(funcType.Params.List, newField)
	} else {
		for i, field := range funcType.Params.List {
			for j, name := range field.Names {
				if name.Name == m.ArgName {
					field.Names = append(field.Names[:j], field.Names[j+1:]...)
					if len(field.Names) == 0 {
						funcType.Params.List = append(funcType.Params.List[:i], funcType.Params.List[i+1:]...)
					}
					return
				}
			}
			if fType, ok := field.Type.(*ast.FuncType); ok {
				m.updateFuncType(fType)
			}
		}
	}
}

func (m *ASTModifier) addArgumentToFunction(fn *ast.FuncDecl) {
	m.updateFuncType(fn.Type)
	m.updateFunctionBody(fn.Body)
}

func (m *ASTModifier) removeArgumentFromFunction(fn *ast.FuncDecl) {
	m.updateFuncType(fn.Type)
}

func (m *ASTModifier) addArgumentToFuncLit(fn *ast.FuncLit) {
	m.updateFuncType(fn.Type)
	m.updateFunctionBody(fn.Body)
}

func (m *ASTModifier) removeArgumentFromFuncLit(fn *ast.FuncLit) {
	m.updateFuncType(fn.Type)
}

func (m *ASTModifier) updateFunctionBody(body *ast.BlockStmt) {
	ast.Inspect(body, func(n ast.Node) bool {
		switch node := n.(type) {
		case *ast.CallExpr:
			m.updateCall(node)
		}
		return true
	})
}

func (m *ASTModifier) UpdateFunctionCalls() {
	ast.Inspect(m.File, func(n ast.Node) bool {
		switch node := n.(type) {
		case *ast.CallExpr:
			m.updateCall(node)
		case *ast.FuncLit:
			m.updateFuncType(node.Type)
		}
		return true
	})
}

func (m *ASTModifier) updateCall(call *ast.CallExpr) {
	if m.shouldUpdateCall(call) {
		if m.IsAdding {
			for _, arg := range call.Args {
				if ident, ok := arg.(*ast.Ident); ok && ident.Name == m.ArgName {
					return // Аргумент уже существует в вызове
				}
			}
			call.Args = append(call.Args, &ast.Ident{Name: m.ArgName})
		} else {
			for i, arg := range call.Args {
				if ident, ok := arg.(*ast.Ident); ok && ident.Name == m.ArgName {
					call.Args = append(call.Args[:i], call.Args[i+1:]...)
					break
				}
			}
		}
	}

	for i, arg := range call.Args {
		switch argNode := arg.(type) {
		case *ast.FuncLit:
			m.updateFuncType(argNode.Type)
		case *ast.Ident:
			if argNode.Obj != nil && argNode.Obj.Decl != nil {
				switch decl := argNode.Obj.Decl.(type) {
				case *ast.FuncDecl:
					m.updateFuncType(decl.Type)
				case *ast.Field:
					if funcType, ok := decl.Type.(*ast.FuncType); ok {
						m.updateFuncType(funcType)
					}
				}
			}
		}
		if funcType, ok := call.Args[i].(*ast.FuncLit); ok {
			m.updateFuncType(funcType.Type)
		}
	}
}

func (m *ASTModifier) WriteModifiedAST(filename string) error {
	var buf bytes.Buffer
	if err := format.Node(&buf, token.NewFileSet(), m.File); err != nil {
		return fmt.Errorf("failed to format AST: %w", err)
	}

	if err := ioutil.WriteFile(filename, buf.Bytes(), 0o644); err != nil {
		return fmt.Errorf("failed to write to file: %w", err)
	}

	return nil
}

func (m *ASTModifier) shouldUpdateCall(call *ast.CallExpr) bool {
	if selExpr, ok := call.Fun.(*ast.SelectorExpr); ok {
		if ident, ok := selExpr.X.(*ast.Ident); ok {
			return ident.Name != "fmt"
		}
	}
	return true
}
