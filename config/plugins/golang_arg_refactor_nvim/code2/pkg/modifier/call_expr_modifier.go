package modifier

import (
	"fmt"
	"go/ast"
	"go/token"
	"log"
	"strings"
)

type CallExprModifier struct {
	functionsToModify  map[string]struct{}
	initialArgCounts   map[string]int
	modifiedFunctions  map[string]bool
	anonymousFuncCount int
	fset               *token.FileSet
	newArgName         string
}

func NewCallExprModifier(functionsToModify []string, fset *token.FileSet) *CallExprModifier {
	modifierMap := make(map[string]struct{})
	initialArgCounts := make(map[string]int)
	for _, funcName := range functionsToModify {
		modifierMap[funcName] = struct{}{}
		initialArgCounts[funcName] = -1
	}
	return &CallExprModifier{
		functionsToModify:  modifierMap,
		initialArgCounts:   initialArgCounts,
		modifiedFunctions:  make(map[string]bool),
		anonymousFuncCount: 0,
		fset:               fset,
	}
}

func (m *CallExprModifier) AddArgument(node ast.Node, argName string) error {
	m.newArgName = argName
	ast.Inspect(node, func(n ast.Node) bool {
		switch x := n.(type) {
		case *ast.FuncLit:
			m.modifyFuncLit(x)
		case *ast.CallExpr:
			m.modifyCallExpr(x)
		}
		return true
	})
	return nil
}

func (m *CallExprModifier) modifyFuncLit(funcLit *ast.FuncLit) {
	funcName := m.getAnonymousFuncName()
	if m.isModified(funcName) {
		return
	}

	// Проверяем, есть ли уже аргумент с таким именем
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

	// Добавляем новый аргумент, только если его еще нет
	if !hasArg {
		newParam := &ast.Field{
			Names: []*ast.Ident{ast.NewIdent(m.newArgName)},
			Type:  ast.NewIdent("string"),
		}
		funcLit.Type.Params.List = append(funcLit.Type.Params.List, newParam)
		log.Printf("Modified anonymous function: %s", funcName)
	}

	m.markAsModified(funcName)

	// Модифицируем тело функции
	ast.Inspect(funcLit.Body, func(n ast.Node) bool {
		switch x := n.(type) {
		case *ast.CallExpr:
			m.modifyCallExpr(x)
		case *ast.FuncLit:
			m.modifyFuncLit(x)
		}
		return true
	})
}

func (m *CallExprModifier) modifyCallExpr(callExpr *ast.CallExpr) {
	funcName, ok := m.extractFuncName(callExpr)
	if !ok {
		return
	}

	shortFuncName := m.getShortFuncName(funcName)

	if m.ShouldModifyFunction(shortFuncName) || strings.HasPrefix(shortFuncName, "anonymous") {
		if m.initialArgCounts[shortFuncName] == -1 {
			m.initialArgCounts[shortFuncName] = len(callExpr.Args)
		}

		expectedArgCount := m.initialArgCounts[shortFuncName] + 1
		if len(callExpr.Args) < expectedArgCount {
			newArg := &ast.Ident{Name: m.newArgName}
			callExpr.Args = append(callExpr.Args, newArg)
			log.Printf("Modified function call: %s", shortFuncName)
		}
	}

	// Обрабатываем случай, когда функция передается как аргумент
	for i, arg := range callExpr.Args {
		if funcLit, ok := arg.(*ast.FuncLit); ok {
			m.modifyFuncLit(funcLit)
			// Если это последний аргумент и мы только что модифицировали его, добавляем новый аргумент к вызову
			if i == len(callExpr.Args)-1 && m.ShouldModifyFunction(shortFuncName) {
				callExpr.Args = append(callExpr.Args, &ast.Ident{Name: m.newArgName})
			}
		}
	}
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
		if innerName, ok := m.extractFuncName(fun); ok {
			return innerName + "()", true
		}
	case *ast.FuncLit:
		return m.getAnonymousFuncName(), true
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

func (m *CallExprModifier) isModified(funcName string) bool {
	return m.modifiedFunctions[funcName]
}

func (m *CallExprModifier) markAsModified(funcName string) {
	m.modifiedFunctions[funcName] = true
}

func (m *CallExprModifier) getAnonymousFuncName() string {
	m.anonymousFuncCount++
	return fmt.Sprintf("anonymous%d", m.anonymousFuncCount)
}

func (m *CallExprModifier) UpdateFunctionDeclarations(
	file *ast.File,
	paramName, paramType string,
	funcDeclMod *FuncDeclModifier,
) error {
	// Этот метод остается пустым, чтобы не изменять сигнатуры публичных функций
	return nil
}
