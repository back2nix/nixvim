package modifier

import (
	"fmt"
	"go/ast"
	"go/token"
	"strings"

	"github.com/back2nix/go-arg-propagation/pkg/logger"
)

type ASTModifier struct {
	functionsToModify  map[string]struct{}
	initialArgCounts   map[string]int
	modifiedFunctions  map[string]bool
	anonymousFuncCount map[token.Pos]bool
	fset               *token.FileSet
	newArgName         string
	newArgType         string
}

func NewASTModifier(functionsToModify []string, fset *token.FileSet) *ASTModifier {
	modifierMap := make(map[string]struct{})
	initialArgCounts := make(map[string]int)

	logger.Log.DebugPrintf("[ASTModifier] functionsToModify: %s", functionsToModify)

	for _, funcName := range functionsToModify {
		modifierMap[funcName] = struct{}{}
		initialArgCounts[funcName] = -1
	}
	return &ASTModifier{
		functionsToModify:  modifierMap,
		initialArgCounts:   initialArgCounts,
		modifiedFunctions:  make(map[string]bool),
		anonymousFuncCount: make(map[token.Pos]bool),
		fset:               fset,
	}
}

func (m *ASTModifier) Modify(node ast.Node, argName, argType string) error {
	m.newArgName = argName
	m.newArgType = argType

	ast.Inspect(node, func(n ast.Node) bool {
		switch x := n.(type) {
		case *ast.FuncDecl:
			m.modifyFuncDecl(x)
		case *ast.FuncLit:
			m.modifyFuncLit(x)
		case *ast.CallExpr:
			m.modifyCallExpr(x)
		}
		return true
	})

	return nil
}

func (m *ASTModifier) modifyFuncDecl(funcDecl *ast.FuncDecl) {
	if !m.ShouldModifyFunction(funcDecl.Name.Name) {
		return
	}

	if m.parameterExists(funcDecl, m.newArgName) {
		return
	}

	newParam := &ast.Field{
		Names: []*ast.Ident{ast.NewIdent(m.newArgName)},
		Type:  ast.NewIdent(m.newArgType),
	}

	if funcDecl.Type.Params == nil {
		funcDecl.Type.Params = &ast.FieldList{}
	}

	funcDecl.Type.Params.List = append(funcDecl.Type.Params.List, newParam)

	if funcDecl.Body != nil {
		m.modifyFunctionBody(funcDecl.Body)
	}

	m.markAsModified(funcDecl.Name.Name)
	logger.Log.DebugPrintf("Modified function declaration: %s", funcDecl.Name.Name)
}

func (m *ASTModifier) modifyFuncLit(funcLit *ast.FuncLit) {
	funcName := m.getAnonymousFuncName(funcLit)
	if !m.ShouldModifyFunction(funcName) {
		return
	}

	if m.isModified(funcName) {
		return
	}

	hasArg := false
	for _, field := range funcLit.Type.Params.List {
		for _, name := range field.Names {
			if name.Name == m.newArgName {
				hasArg = true
				break
			}
		}
		if hasArg {
			break
		}
	}

	if !hasArg {
		newParam := &ast.Field{
			Names: []*ast.Ident{ast.NewIdent(m.newArgName)},
			Type:  ast.NewIdent(m.newArgType),
		}
		funcLit.Type.Params.List = append(funcLit.Type.Params.List, newParam)
		logger.Log.DebugPrintf("Modified anonymous function: %s", funcName)
	}

	m.markAsModified(funcName)

	m.modifyFunctionBody(funcLit.Body)
}

func (m *ASTModifier) modifyCallExpr(callExpr *ast.CallExpr) {
	funcName, ok := m.extractFuncName(callExpr)
	if !ok {
		return
	}

	shortFuncName := m.getShortFuncName(funcName)

	if m.ShouldModifyFunction(shortFuncName) {
		if m.initialArgCounts[shortFuncName] == -1 {
			m.initialArgCounts[shortFuncName] = len(callExpr.Args)
		}

		expectedArgCount := m.initialArgCounts[shortFuncName] + 1
		if len(callExpr.Args) < expectedArgCount {
			newArg := &ast.Ident{Name: m.newArgName}
			callExpr.Args = append(callExpr.Args, newArg)
			logger.Log.DebugPrintf("Modified function call: %s", shortFuncName)
		}
	}

	for i, arg := range callExpr.Args {
		if funcLit, ok := arg.(*ast.FuncLit); ok {
			m.modifyFuncLit(funcLit)
			if i == len(callExpr.Args)-1 && m.ShouldModifyFunction(shortFuncName) {
				callExpr.Args = append(callExpr.Args, &ast.Ident{Name: m.newArgName})
			}
		}
	}
}

func (m *ASTModifier) modifyFunctionBody(body *ast.BlockStmt) {
	ast.Inspect(body, func(n ast.Node) bool {
		if returnStmt, ok := n.(*ast.ReturnStmt); ok {
			for i, expr := range returnStmt.Results {
				if call, ok := expr.(*ast.CallExpr); ok {
					if ident, ok := call.Fun.(*ast.Ident); ok {
						if m.ShouldModifyFunction(ident.Name) {
							call.Args = append(call.Args, ast.NewIdent(m.newArgName))
							returnStmt.Results[i] = call
						}
					}
				}
			}
		}
		return true
	})
}

func (m *ASTModifier) extractFuncName(callExpr *ast.CallExpr) (string, bool) {
	switch fun := callExpr.Fun.(type) {
	case *ast.Ident:
		return fun.Name, true
	case *ast.SelectorExpr:
		if x, ok := fun.X.(*ast.Ident); ok {
			return fmt.Sprintf("%s.%s", x.Name, fun.Sel.Name), true
		}
	case *ast.CallExpr:
		if innerName, ok := m.extractFuncName(fun); ok {
			return innerName + "()", true
		}
	case *ast.FuncLit:
		return m.getAnonymousFuncName(fun), true
	}
	return "", false
}

func (m *ASTModifier) getShortFuncName(funcName string) string {
	parts := strings.Split(funcName, ".")
	return parts[len(parts)-1]
}

func (m *ASTModifier) ShouldModifyFunction(funcName string) bool {
	_, shouldModify := m.functionsToModify[funcName]
	return shouldModify
}

func (m *ASTModifier) isModified(funcName string) bool {
	return m.modifiedFunctions[funcName]
}

func (m *ASTModifier) markAsModified(funcName string) {
	m.modifiedFunctions[funcName] = true
}

func (m *ASTModifier) getAnonymousFuncName(funcLit *ast.FuncLit) string {
	pos := m.fset.Position(funcLit.Pos())
	return fmt.Sprintf("anonymous%d:%d", pos.Line, pos.Column)
}

func (m *ASTModifier) parameterExists(funcDecl *ast.FuncDecl, paramName string) bool {
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

// UpdateFunctionDeclarations is kept for backwards compatibility, but its functionality
// is now integrated into the Modify method
func (m *ASTModifier) UpdateFunctionDeclarations(
	file *ast.File,
	paramName, paramType string,
) error {
	return m.Modify(file, paramName, paramType)
}
