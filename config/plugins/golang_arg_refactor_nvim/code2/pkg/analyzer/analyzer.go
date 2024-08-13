package analyzer

import (
	"fmt"
	"go/ast"
	"go/parser"
	"go/token"
	"log"
)

// CallChainAnalyzer представляет анализатор цепочки вызовов
type CallChainAnalyzer struct {
	callGraph map[string][]string
	anonFuncs map[string]string
	fset      *token.FileSet
}

// NewCallChainAnalyzer создает новый экземпляр CallChainAnalyzer
func NewCallChainAnalyzer() *CallChainAnalyzer {
	return &CallChainAnalyzer{
		callGraph: make(map[string][]string),
		anonFuncs: make(map[string]string),
		fset:      token.NewFileSet(),
	}
}

// AnalyzeCallChain анализирует цепочку вызовов для заданной целевой функции
func (a *CallChainAnalyzer) AnalyzeCallChain(src []byte, targetFunc string) ([]string, error) {
	log.Printf("Starting analysis for target function: %s", targetFunc)

	file, err := parser.ParseFile(a.fset, "", src, parser.AllErrors)
	if err != nil {
		return nil, fmt.Errorf("failed to parse file: %w", err)
	}

	a.buildCallGraph(file)
	chain := a.findCallChain(targetFunc)

	log.Printf("Call chain for %s: %v", targetFunc, chain)
	return chain, nil
}

// buildCallGraph строит граф вызовов функций
func (a *CallChainAnalyzer) buildCallGraph(file *ast.File) {
	var currentFunc string

	ast.Inspect(file, func(n ast.Node) bool {
		switch x := n.(type) {
		case *ast.FuncDecl:
			currentFunc = x.Name.Name
			log.Printf("Analyzing function: %s", currentFunc)
			a.analyzeFuncBody(currentFunc, x.Body)
		case *ast.FuncLit:
			anonName := fmt.Sprintf("anonymous%p", x)
			a.anonFuncs[anonName] = currentFunc
			log.Printf("Analyzing anonymous function in %s: %s", currentFunc, anonName)
			a.analyzeFuncBody(anonName, x.Body)
		}
		return true
	})

	log.Printf("Call graph: %v", a.callGraph)
	log.Printf("Anonymous functions: %v", a.anonFuncs)
}

// analyzeFuncBody анализирует тело функции на наличие вызовов других функций
func (a *CallChainAnalyzer) analyzeFuncBody(funcName string, body *ast.BlockStmt) {
	if body == nil {
		return
	}

	ast.Inspect(body, func(n ast.Node) bool {
		if call, ok := n.(*ast.CallExpr); ok {
			switch fun := call.Fun.(type) {
			case *ast.Ident:
				callee := fun.Name
				a.callGraph[callee] = append(a.callGraph[callee], funcName)
				log.Printf("Found call from %s to %s", funcName, callee)
			case *ast.SelectorExpr:
				if x, ok := fun.X.(*ast.Ident); ok {
					callee := fmt.Sprintf("%s.%s", x.Name, fun.Sel.Name)
					a.callGraph[callee] = append(a.callGraph[callee], funcName)
					log.Printf("Found call from %s to %s", funcName, callee)
				}
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
		log.Printf("Added %s to call chain", current)

		for caller, callees := range a.callGraph {
			for _, callee := range callees {
				if callee == current {
					dfs(caller)
				}
			}
		}
		if parent, ok := a.anonFuncs[current]; ok {
			dfs(parent)
		}
	}

	dfs(targetFunc)
	return chain
}
