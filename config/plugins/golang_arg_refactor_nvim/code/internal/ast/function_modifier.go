package ast

import (
	"go/ast"
)

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
