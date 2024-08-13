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
	return &Calculator{
		cache: make(map[string]int),
	}
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
		result = c.add(a, b)
	case "2":
		result = c.multiply(a, b)
	case "3":
		result = c.complex1(a, b, func(x, y int) int {
			return c.add(x, y)
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

func (c *Calculator) add(x, y int) int {
	return x + y
}

func (c *Calculator) multiply(x, y int) int {
	return x * y
}

func (c *Calculator) complex1(
	a, b int,
	op func(int, int) int,
) int {
	return op(a, b)
}

func (c *Calculator) complex2(
	a, b int,
	op func(int, int) int,
) int {
	return c.add(a, b)
}

func (c *Calculator) complex3(
	a, b int,
	op func(int, int) int,
) int {
	return op(a, b)
}

func main() {
	calc := NewCalculator()
	result := calc.Calculate("1", 10, 20)
	fmt.Println("Result:", result)
}
