package modifier

import (
	"fmt"
	"go/ast"
)

type FuncDeclModifier struct {
	ModifiedFuncs map[string]bool
}

func NewFuncDeclModifier() *FuncDeclModifier {
	return &FuncDeclModifier{
		ModifiedFuncs: make(map[string]bool),
	}
}

func (m *FuncDeclModifier) AddParameter(funcDecl *ast.FuncDecl, paramName, paramType string) error {
	// Check if parameter already exists
	if m.parameterExists(funcDecl, paramName) {
		return fmt.Errorf("parameter %s already exists in function %s", paramName, funcDecl.Name.Name)
	}

	newParam := &ast.Field{
		Names: []*ast.Ident{ast.NewIdent(paramName)},
		Type:  ast.NewIdent(paramType),
	}

	if funcDecl.Type.Params == nil {
		funcDecl.Type.Params = &ast.FieldList{}
	}

	params := funcDecl.Type.Params.List
	if len(params) > 0 && isVariadic(params[len(params)-1]) {
		// If the last parameter is variadic, add the new parameter before it
		newParams := make([]*ast.Field, 0, len(params)+1)
		newParams = append(newParams, params[:len(params)-1]...)
		newParams = append(newParams, newParam)
		newParams = append(newParams, params[len(params)-1])
		funcDecl.Type.Params.List = newParams
	} else {
		// Add the new parameter at the end
		funcDecl.Type.Params.List = append(params, newParam)
	}

	// Modify function body
	if funcDecl.Body != nil {
		m.modifyFunctionBody(funcDecl.Body, paramName)
	}

	m.ModifiedFuncs[funcDecl.Name.Name] = true
	return nil
}

func (m *FuncDeclModifier) parameterExists(funcDecl *ast.FuncDecl, paramName string) bool {
	if funcDecl.Type.Params != nil {
		for _, field := range funcDecl.Type.Params.List {
			for _, name := range field.Names {
				if name.Name == paramName {
					return true
				}
			}
		}
	}
	return false
}

func (m *FuncDeclModifier) modifyFunctionBody(body *ast.BlockStmt, newParamName string) {
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

func isVariadic(field *ast.Field) bool {
	_, ok := field.Type.(*ast.Ellipsis)
	return ok
}
