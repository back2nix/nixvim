package traverser

import (
	"go/ast"

	"github.com/back2nix/go-arg-propagation/pkg/modifier"
	"github.com/back2nix/go-arg-propagation/pkg/parser"
)

type ASTTraverser struct {
	parser      *parser.Parser
	astModifier modifier.IASTModifier
}

func NewASTTraverser(
	parser *parser.Parser,
	astModifier modifier.IASTModifier,
) *ASTTraverser {
	return &ASTTraverser{
		parser:      parser,
		astModifier: astModifier,
	}
}

func (t *ASTTraverser) Traverse(file *ast.File, functionsToModify []string, paramName, paramType string) error {
	// Первый проход: модифицируем объявления функций
	for _, decl := range file.Decls {
		if funcDecl, ok := decl.(*ast.FuncDecl); ok {
			for _, funcName := range functionsToModify {
				if funcDecl.Name.Name == funcName {
					err := t.astModifier.Modify(funcDecl, paramName, paramType)
					if err != nil {
						return err
					}
					break
				}
			}
		}
	}

	// Второй проход: модифицируем функциональные литералы и вызовы функций
	var currentFunc *ast.FuncDecl
	ast.Inspect(file, func(n ast.Node) bool {
		switch node := n.(type) {
		case *ast.FuncDecl:
			currentFunc = node
		case *ast.FuncLit:
			if currentFunc != nil && t.astModifier.ShouldModifyFunction(currentFunc.Name.Name) {
				err := t.astModifier.Modify(node, paramName, paramType)
				if err != nil {
					return false
				}
			}
		case *ast.CallExpr:
			if t.astModifier.ShouldModifyFunction(t.getFuncName(node)) {
				err := t.astModifier.Modify(node, paramName, paramType)
				if err != nil {
					return false
				}
			}
		}
		return true
	})

	return nil
}

func (t *ASTTraverser) getFuncName(callExpr *ast.CallExpr) string {
	switch fun := callExpr.Fun.(type) {
	case *ast.Ident:
		return fun.Name
	case *ast.SelectorExpr:
		if x, ok := fun.X.(*ast.Ident); ok {
			return x.Name + "." + fun.Sel.Name
		}
	}
	return ""
}
