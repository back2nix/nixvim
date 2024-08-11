package ast

import (
	"go/ast"
)

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
	if !m.isTargetFunctionCall(call) {
		return
	}

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

func (m *ASTModifier) isTargetFunctionCall(call *ast.CallExpr) bool {
	switch fun := call.Fun.(type) {
	case *ast.Ident:
		return fun.Name == m.FuncName
	case *ast.SelectorExpr:
		return fun.Sel.Name == m.FuncName
	}
	return false
}

func (m *ASTModifier) shouldUpdateCall(call *ast.CallExpr) bool {
	if selExpr, ok := call.Fun.(*ast.SelectorExpr); ok {
		if ident, ok := selExpr.X.(*ast.Ident); ok {
			return ident.Name != "fmt"
		}
	}
	return true
}
