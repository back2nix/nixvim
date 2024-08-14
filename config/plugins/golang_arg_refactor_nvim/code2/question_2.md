Функци для тестирования которую будет изменять наша основная программа для проброса аргументво
это как программа выглядит после применение к ней нашей программы
```
package main

import (
	"fmt"
	"sync"
)

type Calculator struct {
	cache map[string]int
	mu    sync.Mutex
}

func NewCalculator() *Calculator {
	return &Calculator{cache: make(map[string]int)}
}

func (c *Calculator) Calculate(operation string, a, b int) int {
	c.mu.Lock()
	defer c.mu.Unlock()
	key := fmt.Sprintf("%s:%d:%d", operation, a, b)
	if result, ok := c.cache[key]; ok {
		return result
	}
	var result int
	switch operation {
	case "1":
		result = c.add(a, b, a1)
	case "2":
		result = c.multiply(a, b)
	case "3":
		result = c.complex1(a, b, func(x, y int) int {
			return c.add(x, y, a1)
		})
	case "4":
		result = c.complex2(a, b, func(x, y int) int {
			return x + y
		})
	default:
		result = c.complex3(a, b, func(x, y int) int {
			return x + y
		})
	}
	c.cache[key] = result
	return result
}

func (c *Calculator) add(x, y int, a1 int) int {
	return x + y
}

func (c *Calculator) multiply(x, y int) int {
	return x * y
}

func (c *Calculator) complex1(a, b int, op func(int, int) int) int {
	return op(a, b)
}

func (c *Calculator) complex2(a, b int, op func(int, int) int) int {
	return c.add(a, b, a1)
}

func (c *Calculator) complex3(a, b int, op func(int, int) int) int {
	return op(a, b)
}

func main() {
	calc := NewCalculator()
	result := calc.Calculate("1", 10, 20)
	fmt.Println("Result:", result)
}
```

Описание ошибок совершенных нашей программой  для проброса аргументов

1. Не все функции получили новый параметр:
   - Функции `complex2` также не получили новый параметр.

2. Не все вызовы функций были обновлены:
   - В методе `Calculate` вызов `c.add(a, b)` не был обновлен для передачи нового аргумента.
   - Вызовы `c.complex2` также не были обновлены.

3. Анонимные функции не были изменены:
   - Анонимная функция в вызове `c.complex2` не была изменена вообще.

4. Метод `Calculate` не был обновлен для приема нового параметра:
   - Сигнатура метода `Calculate` осталась прежней, хотя он должен принимать новый параметр `a1`.

5. Функция `main` не была обновлена для передачи нового аргумента в `calc.Calculate`.

Вот цитаты кода, которые нужно исправить:

```go
func (c *Calculator) Calculate(operation string, a, b int) int {
    // Должно быть: func (c *Calculator) Calculate(operation string, a, b, a1 int) int {

func (c *Calculator) complex1(a, b int, op func(int, int) int) int {
    // Все в порядке так как a1 берется из внешнего скоупа

func (c *Calculator) complex2(a, b int, op func(int, int) int) int {
    // Должно быть: func (c *Calculator) complex2(a, b, a1 int, op func(int, int, int) int) int {

case "r":
    result = c.complex2(a, b, func(x, y int) int {
        return x - y
    })
    // Должно быть: result = c.complex2(a, b, a1, func(x, y, a1 int) int {
    //     return x - y
    // })
    // потому эта функци будет передана в там уже в add должно быть три аргумента к тому моменту
    // func (c *Calculator) complex2(a, b int, op func(int, int) int) int {
	// return c.add(a, b, a1)
    // }


func main() {
    calc := NewCalculator()
    result := calc.Calculate("1", 10, 20)
    // Должно быть: result := calc.Calculate("1", 10, 20, someValue)
```

Проблема может быть в следующих файлах:

1. `pkg/modifier/func_decl_modifier.go`: Возможно, этот модификатор не обрабатывает все типы функций корректно.
2. `pkg/modifier/func_lit_modifier.go`: Этот модификатор, вероятно, не обновляет анонимные функции правильно.
3. `pkg/modifier/call_expr_modifier.go`: Этот модификатор может пропускать некоторые вызовы функций.
4. `pkg/traverser/traverser.go`: Обходчик AST может не посещать все необходимые узлы или не применять модификаторы ко всем нужным элементам.

Для исправления этих проблем необходимо:

1. Убедиться, что все объявления функций получают новый параметр.
2. Обновить все вызовы функций для передачи нового аргумента.
3. Модифицировать анонимные функции, добавляя новый параметр и обновляя их вызовы. Но не все анонимные функци а только те которые нужно.
