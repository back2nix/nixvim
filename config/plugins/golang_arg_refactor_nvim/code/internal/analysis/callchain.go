package analysis

import (
	"go/ast"
	"go/parser"
	"go/token"
	"os"
	"path/filepath"
)

// CallChain represents a chain of function calls
type CallChain struct {
	Function string
	Callers  []string
}

// FileInfo holds information about a Go file
type FileInfo struct {
	Filename string
	AST      *ast.File
}

// AnalyzeCallChain analyzes the call chain for a given function in a set of files
func AnalyzeCallChain(targetFunc string, files []string, maxDepth int) (CallChain, error) {
	fileInfos, err := parseFiles(files)
	if err != nil {
		return CallChain{Function: targetFunc}, err
	}

	callers := make([]string, 0)
	visited := make(map[string]bool)
	analyzeCallChainRecursive(targetFunc, fileInfos, &callers, visited, maxDepth)

	return CallChain{Function: targetFunc, Callers: callers}, nil
}

func parseFiles(files []string) ([]FileInfo, error) {
	var fileInfos []FileInfo
	fset := token.NewFileSet()

	for _, file := range files {
		astFile, err := parser.ParseFile(fset, file, nil, 0)
		if err != nil {
			return nil, err
		}
		fileInfos = append(fileInfos, FileInfo{Filename: file, AST: astFile})
	}

	return fileInfos, nil
}

func analyzeCallChainRecursive(currentFunc string, files []FileInfo, callers *[]string, visited map[string]bool, depth int) {
	if depth == 0 || visited[currentFunc] {
		return
	}

	visited[currentFunc] = true
	defer func() { visited[currentFunc] = false }() // Allow revisiting for different paths

	for _, file := range files {
		ast.Inspect(file.AST, func(n ast.Node) bool {
			switch node := n.(type) {
			case *ast.CallExpr:
				if isTargetFunctionCall(node, currentFunc) {
					if enclosingFunc := findEnclosingFunction(file.AST, node); enclosingFunc != nil {
						callerName := getFunctionFullName(enclosingFunc)
						if !contains(*callers, callerName) {
							*callers = append(*callers, callerName)
							analyzeCallChainRecursive(callerName, files, callers, visited, depth-1)
						}
					}
				}
			case *ast.FuncDecl:
				ast.Inspect(node.Body, func(n ast.Node) bool {
					if call, ok := n.(*ast.CallExpr); ok {
						if isTargetFunctionCall(call, currentFunc) {
							callerName := getFunctionFullName(node)
							if !contains(*callers, callerName) {
								*callers = append(*callers, callerName)
								analyzeCallChainRecursive(callerName, files, callers, visited, depth-1)
							}
						}
					}
					return true
				})
			}
			return true
		})
	}
}

func isTargetFunctionCall(call *ast.CallExpr, targetFunc string) bool {
	switch fun := call.Fun.(type) {
	case *ast.Ident:
		return fun.Name == targetFunc
	case *ast.SelectorExpr:
		return fun.Sel.Name == targetFunc
	}
	return false
}

func getFunctionFullName(funcDecl *ast.FuncDecl) string {
	if funcDecl.Recv != nil && len(funcDecl.Recv.List) > 0 {
		recv := funcDecl.Recv.List[0].Type
		if starExpr, ok := recv.(*ast.StarExpr); ok {
			recv = starExpr.X
		}
		if ident, ok := recv.(*ast.Ident); ok {
			return ident.Name + "." + funcDecl.Name.Name
		}
	}
	return funcDecl.Name.Name
}

func findEnclosingFunction(file *ast.File, node ast.Node) *ast.FuncDecl {
	var enclosingFunc *ast.FuncDecl
	ast.Inspect(file, func(n ast.Node) bool {
		switch fn := n.(type) {
		case *ast.FuncDecl:
			if fn.Body != nil && nodeWithinRange(node, fn.Body.Pos(), fn.Body.End()) {
				enclosingFunc = fn
				return false
			}
		}
		return true
	})
	return enclosingFunc
}

func nodeWithinRange(node ast.Node, start, end token.Pos) bool {
	return node.Pos() >= start && node.End() <= end
}

func contains(slice []string, item string) bool {
	for _, s := range slice {
		if s == item {
			return true
		}
	}
	return false
}

// GetAllGoFiles returns all Go files in the given directory and its subdirectories
func GetAllGoFiles(dir string) ([]string, error) {
	var files []string
	err := filepath.Walk(dir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if !info.IsDir() && filepath.Ext(path) == ".go" {
			files = append(files, path)
		}
		return nil
	})
	return files, err
}
