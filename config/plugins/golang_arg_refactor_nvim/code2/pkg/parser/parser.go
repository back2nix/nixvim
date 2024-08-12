package parser

import (
	"go/ast"
	"go/parser"
	"go/token"
)

// Parser represents an AST parser
type Parser struct {
	fset *token.FileSet
}

// NewParser creates a new Parser instance
func NewParser() *Parser {
	return &Parser{
		fset: token.NewFileSet(),
	}
}

// Parse parses the source code and returns the AST
func (p *Parser) Parse(src []byte) (*ast.File, error) {
	return parser.ParseFile(p.fset, "", src, parser.ParseComments)
}

// GetFuncDecl finds a specific function declaration in the AST
func (p *Parser) GetFuncDecl(file *ast.File, funcName string) *ast.FuncDecl {
	for _, decl := range file.Decls {
		if fn, ok := decl.(*ast.FuncDecl); ok && fn.Name.Name == funcName {
			return fn
		}
	}
	return nil
}

// GetAllFuncs returns all function declarations and function literals in the AST
func (p *Parser) GetAllFuncs(file *ast.File) ([]*ast.FuncDecl, []*ast.FuncLit) {
	var funcDecls []*ast.FuncDecl
	var funcLits []*ast.FuncLit

	ast.Inspect(file, func(n ast.Node) bool {
		switch x := n.(type) {
		case *ast.FuncDecl:
			funcDecls = append(funcDecls, x)
		case *ast.FuncLit:
			funcLits = append(funcLits, x)
		}
		return true
	})

	return funcDecls, funcLits
}

// GetFuncLitInFunc finds function literals within a specific named function
func (p *Parser) GetFuncLitInFunc(file *ast.File, funcName string) []*ast.FuncLit {
	var funcLits []*ast.FuncLit

	ast.Inspect(file, func(n ast.Node) bool {
		if fn, ok := n.(*ast.FuncDecl); ok && fn.Name.Name == funcName {
			ast.Inspect(fn, func(m ast.Node) bool {
				if fl, ok := m.(*ast.FuncLit); ok {
					funcLits = append(funcLits, fl)
				}
				return true
			})
			return false // Stop inspecting once we've found the named function
		}
		return true
	})

	return funcLits
}
