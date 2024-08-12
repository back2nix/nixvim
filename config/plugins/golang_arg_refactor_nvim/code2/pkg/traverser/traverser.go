package traverser

import (
	"go/ast"

	"github.com/back2nix/go-arg-propagation/pkg/modifier"
	"github.com/back2nix/go-arg-propagation/pkg/parser"
)

type ASTTraverser struct {
	parser           *parser.Parser
	funcDeclModifier modifier.IFuncDeclModifier
	funcLitModifier  modifier.IFuncLitModifier
	callExprModifier modifier.ICallExprModifier
}

func NewASTTraverser(
	parser *parser.Parser,
	funcDeclModifier modifier.IFuncDeclModifier,
	funcLitModifier modifier.IFuncLitModifier,
	callExprModifier modifier.ICallExprModifier,
) *ASTTraverser {
	return &ASTTraverser{
		parser:           parser,
		funcDeclModifier: funcDeclModifier,
		funcLitModifier:  funcLitModifier,
		callExprModifier: callExprModifier,
	}
}

func (t *ASTTraverser) Traverse(file *ast.File, functionsToModify []string, paramName, paramType string) error {
	var currentFunc *ast.FuncDecl

	ast.Inspect(file, func(n ast.Node) bool {
		switch node := n.(type) {
		case *ast.FuncDecl:
			currentFunc = node
			for _, funcName := range functionsToModify {
				if node.Name.Name == funcName {
					t.funcDeclModifier.AddParameter(node, paramName, paramType)
					break
				}
			}

		case *ast.FuncLit:
			if currentFunc != nil {
				err := t.funcLitModifier.AddParameter(node, paramName, paramType)
				if err != nil {
					// Handle error (in a real implementation, you might want to return this error)
					return false
				}
			}

		case *ast.CallExpr:
			err := t.callExprModifier.AddArgument(node, paramName)
			if err != nil {
				// Handle error
				return false
			}
		}
		return true
	})

	return nil
}
