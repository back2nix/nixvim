package modifier

import (
	"go/ast"
)

// IASTModifier представляет единый интерфейс для модификации AST
type IASTModifier interface {
	// Modify выполняет модификацию AST, добавляя новый параметр к указанным функциям
	Modify(node ast.Node, argName, argType string) error

	// ShouldModifyFunction проверяет, нужно ли модифицировать данную функцию
	ShouldModifyFunction(funcName string) bool

	// UpdateFunctionDeclarations обновляет объявления функций в файле AST
	// Этот метод оставлен для обратной совместимости
	UpdateFunctionDeclarations(file *ast.File, paramName, paramType string) error
}
