package modifier

import (
	"bytes"
	"fmt"
	"go/ast"
	"go/printer"
	"go/token"
	"strings"
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

	fmt.Println("Processing CallExpr:", astToString(callExpr)) // Добавить эту строку

	// Apply the modification to the current CallExpr
	m.modifyCallExpr(callExpr, argName)

	// Recursively traverse the AST within this CallExpr
	ast.Inspect(callExpr, func(n ast.Node) bool {
		switch x := n.(type) {
		case *ast.CallExpr:
			fmt.Println("Found nested CallExpr:", astToString(x)) // Добавить эту строку
			// Recursively modify nested CallExpr
			m.modifyCallExpr(x, argName)
		case *ast.FuncLit:
			fmt.Println("Inspecting FuncLit body") // Добавить эту строку
			// For anonymous functions, traverse their body
			ast.Inspect(x.Body, func(n ast.Node) bool {
				if ce, ok := n.(*ast.CallExpr); ok {
					fmt.Println("Found CallExpr in FuncLit:", astToString(ce)) // Добавить эту строку
					m.modifyCallExpr(ce, argName)
				}
				return true
			})
		}
		return true
	})

	return nil
}

// modifyCallExpr applies the modification to a single CallExpr
func (m *CallExprModifier) modifyCallExpr(callExpr *ast.CallExpr, argName string) {
	funcName, ok := extractFuncName(callExpr)

	if !ok {
		fmt.Println("Cannot modify this call: unable to extract function name")
		return
	}

	// Extract the last part of the function name (after the last dot)
	parts := strings.Split(funcName, ".")
	shortFuncName := parts[len(parts)-1]

	if _, shouldModify := m.functionsToModify[shortFuncName]; !shouldModify {
		return
	}

	// If we haven't seen this function before, record its initial arg count
	if m.initialArgCounts[shortFuncName] == -1 {
		m.initialArgCounts[shortFuncName] = len(callExpr.Args)
	}

	// Check if the function has already been modified
	if len(callExpr.Args) > m.initialArgCounts[shortFuncName] {
		return // Already modified, no need to add argument again
	}

	// Add the new argument
	newArg := &ast.Ident{Name: argName}
	callExpr.Args = append(callExpr.Args, newArg)
}

// Вспомогательная функция для преобразования AST в строку
func astToString(node ast.Node) string {
	var buf bytes.Buffer
	printer.Fprint(&buf, token.NewFileSet(), node)
	return buf.String()
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
