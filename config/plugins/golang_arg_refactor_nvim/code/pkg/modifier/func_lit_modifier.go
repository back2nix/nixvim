package modifier

import (
	"errors"
	"go/ast"
)

type FuncLitModifier struct {
	ModifiedFuncs map[string]bool
}

func NewFuncLitModifier() *FuncLitModifier {
	return &FuncLitModifier{
		ModifiedFuncs: make(map[string]bool),
	}
}

func (m *FuncLitModifier) AddParameter(funcLit *ast.FuncLit, paramName, paramType string, parentFuncName string) error {
	if funcLit == nil {
		return errors.New("funcLit is nil")
	}
	if paramName == "" || paramType == "" {
		return errors.New("paramName and paramType must not be empty")
	}

	// Check if we should modify this function literal based on its parent function
	if !m.ModifiedFuncs[parentFuncName] {
		return nil
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

	// Modify function body to use the new parameter
	m.modifyFunctionBody(funcLit.Body, paramName)

	return nil
}

func (m *FuncLitModifier) modifyFunctionBody(body *ast.BlockStmt, newParamName string) {
	ast.Inspect(body, func(n ast.Node) bool {
		if returnStmt, ok := n.(*ast.ReturnStmt); ok {
			for i, expr := range returnStmt.Results {
				if call, ok := expr.(*ast.CallExpr); ok {
					if ident, ok := call.Fun.(*ast.Ident); ok {
						if m.ModifiedFuncs[ident.Name] {
							call.Args = append(call.Args, ast.NewIdent(newParamName))
							returnStmt.Results[i] = call
						}
					}
				}
			}
		}
		return true
	})
}
