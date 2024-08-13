package traverser

import (
	"go/ast"

	"github.com/back2nix/go-arg-propagation/pkg/modifier"
	"github.com/back2nix/go-arg-propagation/pkg/parser"
)

type ASTTraverser struct {
	parser           *parser.Parser
	funcDeclModifier *modifier.FuncDeclModifier
	funcLitModifier  *modifier.FuncLitModifier
	callExprModifier *modifier.CallExprModifier
}

func NewASTTraverser(
	parser *parser.Parser,
	funcDeclModifier *modifier.FuncDeclModifier,
	funcLitModifier *modifier.FuncLitModifier,
	callExprModifier *modifier.CallExprModifier,
) *ASTTraverser {
	return &ASTTraverser{
		parser:           parser,
		funcDeclModifier: funcDeclModifier,
		funcLitModifier:  funcLitModifier,
		callExprModifier: callExprModifier,
	}
}

func (t *ASTTraverser) Traverse(file *ast.File, functionsToModify []string, paramName, paramType string) error {
	// First pass: modify function declarations
	for _, decl := range file.Decls {
		if funcDecl, ok := decl.(*ast.FuncDecl); ok {
			for _, funcName := range functionsToModify {
				if funcDecl.Name.Name == funcName {
					err := t.funcDeclModifier.AddParameter(funcDecl, paramName, paramType)
					if err != nil {
						return err
					}
					break
				}
			}
		}
	}

	// Second pass: modify function literals and call expressions
	var currentFunc *ast.FuncDecl
	ast.Inspect(file, func(n ast.Node) bool {
		switch node := n.(type) {
		case *ast.FuncDecl:
			currentFunc = node
		case *ast.FuncLit:
			if currentFunc != nil {
				err := t.funcLitModifier.AddParameter(node, paramName, paramType, currentFunc.Name.Name)
				if err != nil {
					return false
				}
			}
		case *ast.CallExpr:
			err := t.callExprModifier.AddArgument(node, paramName)
			if err != nil {
				return false
			}
		}
		return true
	})

	return nil
}
