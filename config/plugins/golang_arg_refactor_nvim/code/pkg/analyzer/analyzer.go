package analyzer

import (
	"fmt"
	"go/ast"
	"go/parser"
	"go/token"

	"github.com/back2nix/go-arg-propagation/pkg/logger"
)

type CallChainAnalyzer struct {
	callGraph map[string][]string
	anonFuncs map[string]string
	fset      *token.FileSet
}

func NewCallChainAnalyzer(fset *token.FileSet) *CallChainAnalyzer {
	return &CallChainAnalyzer{
		callGraph: make(map[string][]string),
		anonFuncs: make(map[string]string),
		fset:      fset,
	}
}

func (a *CallChainAnalyzer) AnalyzeCallChain(src []byte, targetFunc string) ([]string, error) {
	logger.Log.DebugPrintf("[CallChainAnalyzer] Starting analysis for target function: %s", targetFunc)

	file, err := parser.ParseFile(a.fset, "", src, parser.AllErrors)
	if err != nil {
		return nil, fmt.Errorf("failed to parse file: %w", err)
	}

	a.buildCallGraph(file)
	chain := a.findCallChain("", targetFunc)

	if len(chain) > 0 && chain[0] == "main" {
		chain = chain[1:]
	}

	logger.Log.DebugPrintf("[CallChainAnalyzer] Call chain for %s: %v", targetFunc, chain)
	return chain, nil
}

func (a *CallChainAnalyzer) getAnonymousFuncName(funcLit *ast.FuncLit) string {
	pos := a.fset.Position(funcLit.Pos())
	return fmt.Sprintf("anonymous%d:%d", pos.Line, pos.Column)
}

func (a *CallChainAnalyzer) buildCallGraph(file *ast.File) {
	var currentFunc string
	ast.Inspect(file, func(n ast.Node) bool {
		switch x := n.(type) {
		case *ast.FuncDecl:
			currentFunc = x.Name.Name
			logger.Log.DebugPrintf("[CallChainAnalyzer] Analyzing function: %s", currentFunc)
			a.analyzeFuncBody(currentFunc, x.Body)
		case *ast.FuncLit:
			anonName := a.getAnonymousFuncName(x)
			a.anonFuncs[anonName] = currentFunc
			logger.Log.DebugPrintf("[CallChainAnalyzer] Analyzing anonymous function in %s: %s", currentFunc, anonName)
			a.analyzeFuncBody(anonName, x.Body)
		}
		return true
	})
	logger.Log.DebugPrintf("[CallChainAnalyzer] Call graph: %v", a.callGraph)
	logger.Log.DebugPrintf("[CallChainAnalyzer] Anonymous functions: %v", a.anonFuncs)
}

func (a *CallChainAnalyzer) analyzeFuncBody(funcName string, body *ast.BlockStmt) {
	if body == nil {
		return
	}
	ast.Inspect(body, func(n ast.Node) bool {
		if call, ok := n.(*ast.CallExpr); ok {
			switch fun := call.Fun.(type) {
			case *ast.Ident:
				callee := fun.Name
				a.callGraph[funcName] = append(a.callGraph[funcName], callee)
				logger.Log.DebugPrintf("[CallChainAnalyzer] Found call from %s to %s", funcName, callee)
			case *ast.SelectorExpr:
				if x, ok := fun.X.(*ast.Ident); ok {
					callee := fmt.Sprintf("%s.%s", x.Name, fun.Sel.Name)
					a.callGraph[funcName] = append(a.callGraph[funcName], callee)
					logger.Log.DebugPrintf("[CallChainAnalyzer] Found call from %s to %s", funcName, callee)
				}
			case *ast.FuncLit:
				anonName := a.getAnonymousFuncName(fun)
				a.callGraph[funcName] = append(a.callGraph[funcName], anonName)
				logger.Log.DebugPrintf("[CallChainAnalyzer] Found call to anonymous function from %s: %s", funcName, anonName)
			}
		}
		return true
	})
}

func (a *CallChainAnalyzer) findCallChain(start, target string) []string {
	visited := make(map[string]bool)
	path := []string{}
	var result []string

	var dfs func(string) bool
	dfs = func(current string) bool {
		if visited[current] {
			return false
		}
		visited[current] = true
		path = append(path, current)

		logger.Log.DebugPrintf("[CallChainAnalyzer] Visiting function: %s", current)

		if current == target {
			result = make([]string, len(path))
			copy(result, path)
			logger.Log.DebugPrintf("[CallChainAnalyzer] Found target function: %s", target)
			return true
		}

		// Проверяем вызовы обычных функций
		for _, callee := range a.callGraph[current] {
			if dfs(callee) {
				return true
			}
		}

		// Проверяем вызовы анонимных функций
		for anonFunc, parentFunc := range a.anonFuncs {
			if parentFunc == current {
				if dfs(anonFunc) {
					return true
				}
			}
		}

		// Проверяем, является ли текущая функция анонимной
		if parentFunc, isAnon := a.anonFuncs[current]; isAnon {
			if dfs(parentFunc) {
				return true
			}
		}

		path = path[:len(path)-1]
		return false
	}

	// Начинаем поиск с указанной начальной функции
	if start != "" {
		if dfs(start) {
			logger.Log.DebugPrintf("[CallChainAnalyzer] Found path from %s to %s: %v", start, target, result)
			return result
		}
	}

	// Если путь не найден или начальная функция не указана, ищем по всем функциям
	for funcName := range a.callGraph {
		visited = make(map[string]bool)
		path = []string{}
		if dfs(funcName) {
			logger.Log.DebugPrintf("[CallChainAnalyzer] Found path from %s to %s: %v", funcName, target, result)
			return result
		}
	}

	logger.Log.DebugPrintf("[CallChainAnalyzer] No path found to %s", target)
	return nil
}
