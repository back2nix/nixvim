package analyzer

import (
	"fmt"
	"go/ast"
	"go/parser"
	"go/token"
)

// CallChainAnalyzer представляет анализатор цепочки вызовов
type CallChainAnalyzer struct {
	callGraph map[string][]string
	anonFuncs map[string]string
}

// NewCallChainAnalyzer создает новый экземпляр CallChainAnalyzer
func NewCallChainAnalyzer() *CallChainAnalyzer {
	return &CallChainAnalyzer{
		callGraph: make(map[string][]string),
		anonFuncs: make(map[string]string),
	}
}

// AnalyzeCallChain анализирует цепочку вызовов для заданной целевой функции
func (a *CallChainAnalyzer) AnalyzeCallChain(src []byte, targetFunc string) ([]string, error) {
	fset := token.NewFileSet()
	file, err := parser.ParseFile(fset, "", src, 0)
	if err != nil {
		return nil, err
	}

	a.buildCallGraph(file)
	return a.findCallChain(targetFunc), nil
}

// buildCallGraph строит граф вызовов функций
func (a *CallChainAnalyzer) buildCallGraph(file *ast.File) {
	var currentFunc string

	ast.Inspect(file, func(n ast.Node) bool {
		switch x := n.(type) {
		case *ast.FuncDecl:
			currentFunc = x.Name.Name
			a.analyzeFuncBody(currentFunc, x.Body)
		case *ast.FuncLit:
			anonName := fmt.Sprintf("anonymous%p", x)
			a.anonFuncs[anonName] = currentFunc
			a.analyzeFuncBody(anonName, x.Body)
		}
		return true
	})
}

// analyzeFuncBody анализирует тело функции на наличие вызовов других функций
func (a *CallChainAnalyzer) analyzeFuncBody(funcName string, body *ast.BlockStmt) {
	if body == nil {
		return
	}

	ast.Inspect(body, func(n ast.Node) bool {
		if call, ok := n.(*ast.CallExpr); ok {
			if ident, ok := call.Fun.(*ast.Ident); ok {
				callee := ident.Name
				a.callGraph[callee] = append(a.callGraph[callee], funcName)
			}
		}
		return true
	})
}

// findCallChain находит цепочку вызовов для целевой функции
func (a *CallChainAnalyzer) findCallChain(targetFunc string) []string {
	visited := make(map[string]bool)
	var chain []string

	var dfs func(string)
	dfs = func(current string) {
		if visited[current] {
			return
		}
		visited[current] = true
		chain = append(chain, current)

		for _, caller := range a.callGraph[current] {
			dfs(caller)
		}
		if parent, ok := a.anonFuncs[current]; ok {
			dfs(parent)
		}
	}

	dfs(targetFunc)
	return chain
}
