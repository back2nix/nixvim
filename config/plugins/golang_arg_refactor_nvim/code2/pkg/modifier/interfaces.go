package modifier

import (
	"go/ast"
)

type IFuncDeclModifier interface {
	AddParameter(funcDecl *ast.FuncDecl, paramName, paramType string) error
}

type IFuncLitModifier interface {
	AddParameter(funcLit *ast.FuncLit, paramName, paramType string) error
}

type ICallExprModifier interface {
	AddArgument(callExpr *ast.CallExpr, argName string) error
}
