package modifier

import (
	"fmt"
	"go/ast"
)

// CallExprModifier modifies function calls to add a new argument
type CallExprModifier struct {
	functionsToModify map[string]struct{}
	initialArgCounts  map[string]int
}

// NewCallExprModifier creates a new CallExprModifier
func NewCallExprModifier(functionsToModify []string) *CallExprModifier {
	modifierMap := make(map[string]struct{})
	initialArgCounts := make(map[string]int)
	for _, funcName := range functionsToModify {
		modifierMap[funcName] = struct{}{}
		initialArgCounts[funcName] = -1 // We'll set the actual count when we first see the function
	}
	return &CallExprModifier{
		functionsToModify: modifierMap,
		initialArgCounts:  initialArgCounts,
	}
}

// AddArgument adds a new argument to the function call if it's in the list of functions to modify
func (m *CallExprModifier) AddArgument(callExpr *ast.CallExpr, argName string) error {
	if callExpr == nil {
		return fmt.Errorf("nil CallExpr")
	}

	funcName, ok := extractFuncName(callExpr)
	if !ok {
		return nil // Not an error, just can't modify this call
	}

	if _, shouldModify := m.functionsToModify[funcName]; !shouldModify {
		return nil // Not an error, this function is not in our list to modify
	}

	// If we haven't seen this function before, record its initial arg count
	if m.initialArgCounts[funcName] == -1 {
		m.initialArgCounts[funcName] = len(callExpr.Args)
	}

	// Check if the function has already been modified
	if len(callExpr.Args) > m.initialArgCounts[funcName] {
		return nil // Already modified, no need to add argument again
	}

	// Add the new argument
	newArg := &ast.Ident{Name: argName}
	callExpr.Args = append(callExpr.Args, newArg)
	return nil
}

func (m *CallExprModifier) expectedArgCount(callExpr *ast.CallExpr) int {
	funcName, _ := extractFuncName(callExpr)
	if _, shouldModify := m.functionsToModify[funcName]; shouldModify {
		return len(callExpr.Args) + 1
	}
	return len(callExpr.Args)
}

// extractFuncName attempts to extract the function name from a CallExpr
func extractFuncName(callExpr *ast.CallExpr) (string, bool) {
	switch fun := callExpr.Fun.(type) {
	case *ast.Ident:
		return fun.Name, true
	case *ast.SelectorExpr:
		if ident, ok := fun.X.(*ast.Ident); ok {
			return ident.Name + "." + fun.Sel.Name, true
		}
	}
	return "", false
}
