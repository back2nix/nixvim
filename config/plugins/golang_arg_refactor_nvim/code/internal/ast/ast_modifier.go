package ast

import (
	"bytes"
	"fmt"
	"go/ast"
	"go/format"
	"go/token"
	"io/ioutil"
)

type ASTModifier struct {
	File     *ast.File
	FuncName string
	ArgName  string
	ArgType  string
	IsAdding bool
}

func NewASTModifier(file *ast.File, funcName, argName, argType string, isAdding bool) *ASTModifier {
	return &ASTModifier{
		File:     file,
		FuncName: funcName,
		ArgName:  argName,
		ArgType:  argType,
		IsAdding: isAdding,
	}
}

func (m *ASTModifier) ModifyFunction() error {
	ast.Inspect(m.File, func(n ast.Node) bool {
		switch node := n.(type) {
		case *ast.FuncDecl:
			if m.IsAdding {
				m.addArgumentToFunction(node)
			} else {
				m.removeArgumentFromFunction(node)
			}
		case *ast.FuncLit:
			if m.IsAdding {
				m.addArgumentToFuncLit(node)
			} else {
				m.removeArgumentFromFuncLit(node)
			}
		}
		return true
	})

	m.UpdateFunctionCalls()
	return nil
}

func (m *ASTModifier) WriteModifiedAST(filename string) error {
	var buf bytes.Buffer
	if err := format.Node(&buf, token.NewFileSet(), m.File); err != nil {
		return fmt.Errorf("failed to format AST: %w", err)
	}

	if err := ioutil.WriteFile(filename, buf.Bytes(), 0o644); err != nil {
		return fmt.Errorf("failed to write to file: %w", err)
	}

	return nil
}
