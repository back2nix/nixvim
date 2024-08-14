package modifier

import (
	"go/ast"
)

type IFuncDeclModifier interface {
	AddParameter(funcDecl *ast.FuncDecl, paramName, paramType string) error
}

type IFuncLitModifier interface {
	AddParameter(funcLit *ast.FuncLit, paramName, paramType string, parentFuncName string) error
}

type ICallExprModifier interface {
	AddArgument(node ast.Node, argName, argType string) error
	ShouldModifyFunction(funcName string) bool
	UpdateFunctionDeclarations(file *ast.File, paramName, paramType string, funcDeclMod *FuncDeclModifier) error
}
