1. `FuncDeclModifier`:
   - Должен принимать объявление функции (`*ast.FuncDecl`) и информацию о новом параметре (имя и тип).
   - Проверять, есть ли у функции список параметров (`Params`). Если нет, создавать новый.
   - Создавать новый параметр (`*ast.Field`) с заданным именем и типом.
   - Добавлять новый параметр в конец списка параметров функции.
   - Если функция имеет тело (`Body`), должен пройтись по всем возвращаемым выражениям (`return` statements) и добавить новый аргумент (обычно `nil` или значение по умолчанию) ко всем вызовам функций, которые также модифицируются.
   - Должен корректно обрабатывать функции с переменным числом аргументов (varargs).
   - Не должен модифицировать функции, которые уже имеют параметр с таким же именем.

2. `FuncLitModifier`:
   - Должен работать аналогично `FuncDeclModifier`, но для анонимных функций (`*ast.FuncLit`).
   - Принимать анонимную функцию и информацию о новом параметре.
   - Добавлять новый параметр в конец списка параметров анонимной функции.
   - Также обрабатывать тело анонимной функции, добавляя новый аргумент к вызовам модифицируемых функций.
   - Должен учитывать контекст, в котором находится анонимная функция (например, если она является аргументом другой функции).

3. `CallExprModifier`:
   - Принимать выражение вызова функции (`*ast.CallExpr`) и информацию о новом аргументе.
   - Проверять, является ли вызываемая функция одной из тех, которые нужно модифицировать (по имени или другому критерию).
   - Если функция подлежит модификации, добавлять новый аргумент в конец списка аргументов вызова.
   - Должен корректно обрабатывать вызовы функций с переменным числом аргументов.
   - Не должен добавлять аргумент, если вызов уже содержит корректное количество аргументов (чтобы избежать повторного добавления при многократном применении).
   - Должен уметь работать с разными типами вызовов (например, методы структур, функции пакетов).

Общие требования для всех модификаторов:
- Должны быть идемпотентными (повторное применение не должно изменять уже модифицированный код).
- Должны сохранять существующие комментарии и форматирование кода.
- Должны корректно обрабатывать краевые случаи (например, пустые функции, функции без параметров).
- Должны возвращать ошибку в случае невозможности выполнить модификацию.

Для корректной работы `Traverse`:
- Модификаторы должны быть применены в правильном порядке: сначала `FuncDeclModifier` и `FuncLitModifier`, затем `CallExprModifier`.
- `Traverse` должен передавать в модификаторы правильный контекст (например, список имен функций для модификации).
- `Traverse` должен обеспечивать, что все необходимые узлы AST посещаются и обрабатываются соответствующими модификаторами.

Если все эти компоненты будут работать корректно и согласованно, `Traverse` сможет успешно выполнить задачу по добавлению нового параметра к функциям и соответствующего аргумента ко всем их вызовам в коде.


Давай выполнять пункт 3 нужно довести до ума этот модуль и тест для него чтобы он работал корректно и на него могли положиться другие модули которые от него зависят

Вот модуль:

File: call_expr_modifier.go
```
package modifier

import (
	"go/ast"
)

// CallExprModifier modifies function calls to add a new argument
type CallExprModifier struct {
	functionsToModify map[string]struct{}
}

// NewCallExprModifier creates a new CallExprModifier
func NewCallExprModifier(functionsToModify []string) ICallExprModifier {
	modifierMap := make(map[string]struct{})
	for _, funcName := range functionsToModify {
		modifierMap[funcName] = struct{}{}
	}
	return CallExprModifier{
		functionsToModify: modifierMap,
	}
}

// AddArgument adds a new argument to the function call if it's in the list of functions to modify
func (m CallExprModifier) AddArgument(callExpr *ast.CallExpr, argName string) error {
	if callExpr == nil {
		return nil
	}
	funcName, ok := extractFuncName(callExpr)
	if !ok {
		return nil
	}
	if _, shouldModify := m.functionsToModify[funcName]; shouldModify {
		newArg := &ast.Ident{Name: argName}
		callExpr.Args = append(callExpr.Args, newArg)
	}
	return nil
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
```

File: call_expr_modifier_test.go
```
package modifier

import (
	"go/ast"
	"go/parser"
	"go/printer"
	"go/token"
	"strings"
	"testing"
)

func TestCallExprModifier_AddArgument(t *testing.T) {
	tests := []struct {
		name              string
		code              string
		functionsToModify []string
		argName           string
		expectedCode      string
	}{
		{
			name: "Modify simple function call",
			code: `package main

func main() {
	foo()
}`,
			functionsToModify: []string{"foo"},
			argName:           "newArg",
			expectedCode: `package main

func main() {
	foo(newArg)
}`,
		},
		{
			name: "Don't modify unrelated function call",
			code: `package main

func main() {
	bar()
}`,
			functionsToModify: []string{"foo"},
			argName:           "newArg",
			expectedCode: `package main

func main() {
	bar()
}`,
		},
		{
			name: "Modify method call",
			code: `package main

func main() {
	obj.Method()
}`,
			functionsToModify: []string{"obj.Method"},
			argName:           "newArg",
			expectedCode: `package main

func main() {
	obj.Method(newArg)
}`,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			fset := token.NewFileSet()
			file, err := parser.ParseFile(fset, "", tt.code, parser.ParseComments)
			if err != nil {
				t.Fatalf("Failed to parse code: %v", err)
			}

			modifier := NewCallExprModifier(tt.functionsToModify)

			ast.Inspect(file, func(n ast.Node) bool {
				if callExpr, ok := n.(*ast.CallExpr); ok {
					err := modifier.AddArgument(callExpr, tt.argName)
					if err != nil {
						t.Fatalf("AddArgument failed: %v", err)
					}
				}
				return true
			})

			got := normalizeWhitespace(astToString(fset, file))
			want := normalizeWhitespace(tt.expectedCode)

			if got != want {
				t.Errorf(
					"Modified code does not match expected.\nGot (len=%d):\n%q\nWant (len=%d):\n%q",
					len(got),
					got,
					len(want),
					want,
				)
			}
		})
	}
}

// astToString converts an AST to a string representation of the code
func astToString(fset *token.FileSet, node ast.Node) string {
	var buf strings.Builder
	err := printer.Fprint(&buf, fset, node)
	if err != nil {
		return ""
	}
	return buf.String()
}

// normalizeWhitespace removes leading and trailing whitespace from each line,
// ensures consistent newline characters, and trims the final newline
func normalizeWhitespace(s string) string {
	lines := strings.Split(strings.TrimSpace(s), "\n")
	for i, line := range lines {
		lines[i] = strings.TrimSpace(line)
	}
	return strings.Join(lines, "\n")
}
```
