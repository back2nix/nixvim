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

	// Reverse the order of callers to get the correct chain
	for i, j := 0, len(callers)-1; i < j; i, j = i+1, j-1 {
		callers[i], callers[j] = callers[j], callers[i]
	}

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
	for _, file := range files {
		ast.Inspect(file.AST, func(n ast.Node) bool {
			if call, ok := n.(*ast.CallExpr); ok {
				if ident, ok := call.Fun.(*ast.Ident); ok && ident.Name == currentFunc {
					if funcDecl := findEnclosingFunction(file.AST, call); funcDecl != nil {
						callerName := funcDecl.Name.Name
						*callers = append(*callers, callerName)
						analyzeCallChainRecursive(callerName, files, callers, visited, depth-1)
					}
				}
			}
			return true
		})
	}
	visited[currentFunc] = false // Allow revisiting for different paths
}

func findEnclosingFunction(file *ast.File, node ast.Node) *ast.FuncDecl {
	var enclosingFunc *ast.FuncDecl
	ast.Inspect(file, func(n ast.Node) bool {
		if fd, ok := n.(*ast.FuncDecl); ok {
			if fd.Body != nil && nodeWithinRange(node, fd.Body.Pos(), fd.Body.End()) {
				enclosingFunc = fd
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
