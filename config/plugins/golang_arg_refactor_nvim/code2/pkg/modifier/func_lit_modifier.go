package modifier

import (
	"errors"
	"go/ast"
)

type FuncLitModifier struct{}

func NewFuncLitModifier() IFuncLitModifier {
	return FuncLitModifier{}
}

func (m FuncLitModifier) AddParameter(funcLit *ast.FuncLit, paramName, paramType string) error {
	if funcLit == nil {
		return errors.New("funcLit is nil")
	}
	if paramName == "" || paramType == "" {
		return errors.New("paramName and paramType must not be empty")
	}
	// Check if the parameter already exists
	for _, field := range funcLit.Type.Params.List {
		for _, ident := range field.Names {
			if ident.Name == paramName {
				return nil // Parameter already exists, no modification needed
			}
		}
	}
	// Create new parameter
	newParam := &ast.Field{
		Names: []*ast.Ident{ast.NewIdent(paramName)},
		Type:  ast.NewIdent(paramType),
	}
	// Add new parameter to the function's parameter list
	funcLit.Type.Params.List = append(funcLit.Type.Params.List, newParam)
	return nil
}
