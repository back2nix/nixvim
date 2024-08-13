package modifier

import (
	"fmt"
	"go/ast"
	"go/token"
	"log"
	"strings"
)

type CallExprModifier struct {
	functionsToModify map[string]struct{}
	initialArgCounts  map[string]int
	fset              *token.FileSet
}

func NewCallExprModifier(functionsToModify []string, fset *token.FileSet) *CallExprModifier {
	modifierMap := make(map[string]struct{})
	initialArgCounts := make(map[string]int)
	for _, funcName := range functionsToModify {
		modifierMap[funcName] = struct{}{}
		initialArgCounts[funcName] = -1
	}
	return &CallExprModifier{
		functionsToModify: modifierMap,
		initialArgCounts:  initialArgCounts,
		fset:              fset,
	}
}

func (m *CallExprModifier) AddArgument(node ast.Node, argName string) error {
	log.Printf("AddArgument called with argName: %s", argName)
	ast.Inspect(node, func(n ast.Node) bool {
		switch x := n.(type) {
		case *ast.CallExpr:
			log.Printf("Inspecting CallExpr: %v", x)
			m.modifyCallExpr(x, argName)
		case *ast.FuncLit:
			log.Printf("Inspecting FuncLit: %v", x)
			ast.Inspect(x.Body, func(n ast.Node) bool {
				if ce, ok := n.(*ast.CallExpr); ok {
					log.Printf("Inspecting nested CallExpr in FuncLit: %v", ce)
					m.modifyCallExpr(ce, argName)
				}
				return true
			})
		}
		return true
	})
	return nil
}

func (m *CallExprModifier) modifyCallExpr(callExpr *ast.CallExpr, argName string) {
	funcName, ok := m.extractFuncName(callExpr)
	if !ok {
		log.Printf("Could not extract function name from CallExpr: %v", callExpr)
		return
	}
	log.Printf("Checking CallExpr for function: %s", funcName)

	shortFuncName := m.getShortFuncName(funcName)

	if !m.ShouldModifyFunction(shortFuncName) {
		log.Printf("Skipping modification for function: %s", shortFuncName)
		return
	}

	log.Printf("Modifying CallExpr for function: %s", funcName)

	if m.initialArgCounts[shortFuncName] == -1 {
		m.initialArgCounts[shortFuncName] = len(callExpr.Args)
	}

	expectedArgCount := m.initialArgCounts[shortFuncName] + 1
	if len(callExpr.Args) >= expectedArgCount {
		log.Printf("Function %s already has expected number of arguments", funcName)
		return
	}

	newArg := &ast.Ident{Name: argName}
	callExpr.Args = append(callExpr.Args, newArg)
	log.Printf("Added argument '%s' to function call: %s", argName, funcName)
}

func (m *CallExprModifier) extractFuncName(callExpr *ast.CallExpr) (string, bool) {
	switch fun := callExpr.Fun.(type) {
	case *ast.Ident:
		return fun.Name, true
	case *ast.SelectorExpr:
		if x, ok := fun.X.(*ast.Ident); ok {
			return fmt.Sprintf("%s.%s", x.Name, fun.Sel.Name), true
		}
	case *ast.CallExpr:
		// Обработка вызовов вида f()()
		if innerName, ok := m.extractFuncName(fun); ok {
			return innerName + "()", true
		}
	}
	return "", false
}

func (m *CallExprModifier) getShortFuncName(funcName string) string {
	parts := strings.Split(funcName, ".")
	return parts[len(parts)-1]
}

func (m *CallExprModifier) ShouldModifyFunction(funcName string) bool {
	_, shouldModify := m.functionsToModify[funcName]
	return shouldModify
}

func (m *CallExprModifier) UpdateFunctionDeclarations(
	file *ast.File,
	paramName, paramType string,
	funcDeclMod *FuncDeclModifier,
) error {
	for _, decl := range file.Decls {
		if funcDecl, ok := decl.(*ast.FuncDecl); ok {
			if m.ShouldModifyFunction(funcDecl.Name.Name) {
				err := funcDeclMod.AddParameter(funcDecl, paramName, paramType)
				if err != nil {
					return fmt.Errorf("failed to update function declaration %s: %w", funcDecl.Name.Name, err)
				}
			}
		}
	}
	return nil
}
