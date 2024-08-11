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

func (c *Calculator) Calculate(operation string, a, b int, z int) int {
	c.mu.Lock()
	defer c.mu.Unlock()
	key := fmt.Sprintf("%s:%d:%d", operation, a, b)
	if result, ok := c.cache[key]; ok {
		return result
	}
	var result int
	switch operation {
	case "add":
		result = c.add(a, b, z)
	case "multiply":
		result = c.multiply(a, b)
	case "complexAdd":
		result = c.complexOperationAdd(a, b, func(x, y int) int { return c.add(x, y, z) })
	case "complexAdd2":
		result = c.complexOperationAdd2(a, b, func(x, y, z int) int { return x + y }, z)
	default:
		result = c.complexOperation(a, b, z, func(x, y, z int) int { return x + y })
	}
	c.cache[key] = result
	return result
}

func (c *Calculator) add(x, y int, z int) int {
	return x + y
}

func (c *Calculator) multiply(x, y int) int {
	return x * y
}

func (c *Calculator) complexOperationAdd2(a, b int, op func(int, int, int) int, z int) int {
	return c.add(a, b, z)
}

func (c *Calculator) complexOperationAdd(a, b int, op func(int, int) int) int {
	return op(a, b)
}

func (c *Calculator) complexOperation(a, b, z int, op func(int, int, int) int) int {
	return op(a, b, z)
}

func main() {
	calc := NewCalculator()
	result := calc.Calculate("complexAdd2", 10, 20, 0)
	fmt.Println("Result:", result)
}
