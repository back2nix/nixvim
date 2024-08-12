package parser

import (
	"testing"
)

func TestParse(t *testing.T) {
	tests := []struct {
		name    string
		src     string
		wantErr bool
	}{
		{
			name: "Valid Go code",
			src: `
package main

func main() {
	println("Hello, World!")
}`,
			wantErr: false,
		},
		{
			name:    "Invalid Go code",
			src:     "This is not valid Go code",
			wantErr: true,
		},
	}

	parser := NewParser()

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			_, err := parser.Parse([]byte(tt.src))
			if (err != nil) != tt.wantErr {
				t.Errorf("Parse() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}

func TestGetFuncDecl(t *testing.T) {
	src := `
package main

func foo() {}
func bar() {}
`

	parser := NewParser()
	file, err := parser.Parse([]byte(src))
	if err != nil {
		t.Fatalf("Failed to parse test source: %v", err)
	}

	tests := []struct {
		name     string
		funcName string
		want     bool
	}{
		{"Existing function", "foo", true},
		{"Another existing function", "bar", true},
		{"Non-existing function", "baz", false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := parser.GetFuncDecl(file, tt.funcName)
			if (got != nil) != tt.want {
				t.Errorf("GetFuncDecl() = %v, want %v", got, tt.want)
			}
			if got != nil && got.Name.Name != tt.funcName {
				t.Errorf("GetFuncDecl() returned wrong function, got %s, want %s", got.Name.Name, tt.funcName)
			}
		})
	}
}

func TestGetAllFuncs(t *testing.T) {
	src := `
package main

func foo() {}

func bar() {
	_ = func() {}
}

var _ = func() {}
`

	parser := NewParser()
	file, err := parser.Parse([]byte(src))
	if err != nil {
		t.Fatalf("Failed to parse test source: %v", err)
	}

	funcDecls, funcLits := parser.GetAllFuncs(file)

	if len(funcDecls) != 2 {
		t.Errorf("Expected 2 function declarations, got %d", len(funcDecls))
	}

	if len(funcLits) != 2 {
		t.Errorf("Expected 2 function literals, got %d", len(funcLits))
	}
}

func TestGetFuncLitInFunc(t *testing.T) {
	src := `
package main

func foo() {
	_ = func() {}
	_ = func() {}
}

func bar() {}
`

	parser := NewParser()
	file, err := parser.Parse([]byte(src))
	if err != nil {
		t.Fatalf("Failed to parse test source: %v", err)
	}

	fooLits := parser.GetFuncLitInFunc(file, "foo")
	barLits := parser.GetFuncLitInFunc(file, "bar")

	if len(fooLits) != 2 {
		t.Errorf("Expected 2 function literals in foo, got %d", len(fooLits))
	}

	if len(barLits) != 0 {
		t.Errorf("Expected 0 function literals in bar, got %d", len(barLits))
	}
}
