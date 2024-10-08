package main

import (
	"errors"
	"fmt"
	"sync"
	"time"
)

type Processor interface {
	Process(data string) (string, error)
}
type DataManager struct{ data string }

func (dm *DataManager) Process(data string) (string, error) {
	return fmt.Sprintf("Processed: %s", data), nil
}

var GlobalVariable = "Do not modify this"

func main() {
	func() {
		func() {
			result := complexFunction(42, "test")
			fmt.Println(result)
		}()
	}()
}

func complexFunction(x int, s string) string {
	dm := &DataManager{data: s}
	defer func() {
		if r := recover(); r != nil {
			fmt.Println("Recovered from panic:", r)
		}
	}()
	var recursiveFunc func(int) int
	recursiveFunc = func(n int) int {
		if n <= 1 {
			return 1
		}
		return n * recursiveFunc(n-1)
	}
	ch := make(chan int)
	go func() {
		time.Sleep(time.Millisecond * 100)
		ch <- recursiveFunc(5)
	}()
	var wg sync.WaitGroup
	wg.Add(1)
	go func() {
		defer wg.Done()
		fmt.Println("Goroutine executed")
	}()
	func() {
		func() {
			untouchedFunction()
		}()
	}()

	untouchedFunction()

	if x > 10 {
		for i := 0; i < 3; i++ {
			s += string(rune(x + i))
		}
	}
	result, err := processData(dm, s)
	if err != nil {
		return fmt.Sprintf("Error: %v", err)
	}
	wg.Wait()
	factorialResult := <-ch
	return fmt.Sprintf("Result: %s, Factorial: %d", result, factorialResult)
}

func processData(p Processor, data string) (string, error) {
	if data == "" {
		return "", errors.New("empty data")
	}
	return p.Process(data)
}

func untouchedFunction() {
	fmt.Println("This function should not be modified")
}

func init() {
	fmt.Println("Initialization complete")
}
