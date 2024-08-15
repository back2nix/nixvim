package analyzer

import (
	"fmt"
	"go/ast"
	"go/parser"
	"go/token"

	"github.com/back2nix/go-arg-propagation/pkg/logger"
)

type CallChainAnalyzer struct {
	callGraph    map[string][]string
	anonFuncs    map[string]string
	reverseCalls map[string][]string
	fset         *token.FileSet
}

func NewCallChainAnalyzer(fset *token.FileSet) *CallChainAnalyzer {
	return &CallChainAnalyzer{
		callGraph:    make(map[string][]string),
		anonFuncs:    make(map[string]string),
		reverseCalls: make(map[string][]string),
		fset:         fset,
	}
}

func removeMain(chain []string) []string {
	for i, v := range chain {
		if v == "main" {
			return append(chain[:i], chain[i+1:]...)
		}
	}
	return chain
}

func (a *CallChainAnalyzer) AnalyzeCallChain(src []byte, targetFunc string) ([]string, error) {
	logger.Log.DebugPrintf("[CallChainAnalyzer] Starting analysis for target function: %s", targetFunc)

	file, err := parser.ParseFile(a.fset, "", src, parser.AllErrors)
	if err != nil {
		return nil, fmt.Errorf("failed to parse file: %w", err)
	}

	a.buildCallGraph(file)
	chain := a.findCompleteCallChain(targetFunc)

	chain = removeMain(chain)

	logger.Log.DebugPrintf("[CallChainAnalyzer] Complete call chain for %s: %v", targetFunc, chain)
	return chain, nil
}

func (a *CallChainAnalyzer) getAnonymousFuncName(funcLit *ast.FuncLit) string {
	pos := a.fset.Position(funcLit.Pos())
	return fmt.Sprintf("anonymous%d:%d", pos.Line, pos.Column)
}

func (a *CallChainAnalyzer) buildCallGraph(file *ast.File) {
	var stack []string

	var inspectNode func(ast.Node) bool
	inspectNode = func(n ast.Node) bool {
		switch x := n.(type) {
		case *ast.FuncDecl:
			funcName := x.Name.Name
			stack = append(stack, funcName)
			a.analyzeFuncBody(funcName, x.Body)
			stack = stack[:len(stack)-1]
		case *ast.FuncLit:
			anonName := a.getAnonymousFuncName(x)
			parent := ""
			if len(stack) > 0 {
				parent = stack[len(stack)-1]
			}
			a.anonFuncs[anonName] = parent
			stack = append(stack, anonName)
			a.analyzeFuncBody(anonName, x.Body)
			stack = stack[:len(stack)-1]
		}
		return true
	}

	ast.Inspect(file, inspectNode)

	logger.Log.DebugPrintf("[CallChainAnalyzer] Call graph: %v", a.callGraph)
	logger.Log.DebugPrintf("[CallChainAnalyzer] Anonymous functions: %v", a.anonFuncs)
	logger.Log.DebugPrintf("[CallChainAnalyzer] Reverse calls: %v", a.reverseCalls)
}

func (a *CallChainAnalyzer) analyzeFuncBody(funcName string, body *ast.BlockStmt) {
	if body == nil {
		return
	}

	ast.Inspect(body, func(n ast.Node) bool {
		switch x := n.(type) {
		case *ast.CallExpr:
			callee := a.getCalleeName(x.Fun)
			if callee != "" {
				a.callGraph[funcName] = append(a.callGraph[funcName], callee)
				a.reverseCalls[callee] = append(a.reverseCalls[callee], funcName)
				logger.Log.DebugPrintf("[CallChainAnalyzer] Found call from %s to %s", funcName, callee)
			}
		case *ast.FuncLit:
			anonName := a.getAnonymousFuncName(x)
			a.anonFuncs[anonName] = funcName
			logger.Log.DebugPrintf("[CallChainAnalyzer] Found nested anonymous function in %s: %s", funcName, anonName)
		}
		return true
	})
}

func (a *CallChainAnalyzer) getCalleeName(expr ast.Expr) string {
	switch x := expr.(type) {
	case *ast.Ident:
		return x.Name
	case *ast.SelectorExpr:
		if ident, ok := x.X.(*ast.Ident); ok {
			return fmt.Sprintf("%s.%s", ident.Name, x.Sel.Name)
		}
	case *ast.FuncLit:
		return a.getAnonymousFuncName(x)
	}
	return ""
}

func (a *CallChainAnalyzer) findCompleteCallChain(target string) []string {
	var result []string
	visited := make(map[string]bool)

	var dfs func(string)
	dfs = func(current string) {
		if visited[current] {
			return
		}
		visited[current] = true
		result = append([]string{current}, result...)

		callers := a.reverseCalls[current]
		for _, caller := range callers {
			dfs(caller)
		}

		if parent, isAnon := a.anonFuncs[current]; isAnon {
			dfs(parent)
		}
	}

	dfs(target)

	// Remove duplicates while preserving order
	seen := make(map[string]bool)
	var uniqueResult []string
	for i := len(result) - 1; i >= 0; i-- {
		if !seen[result[i]] {
			seen[result[i]] = true
			uniqueResult = append([]string{result[i]}, uniqueResult...)
		}
	}

	return uniqueResult
}
