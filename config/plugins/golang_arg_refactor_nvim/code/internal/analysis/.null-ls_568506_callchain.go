package analysis

import (
	"go/ast"
	"go/parser"
	"go/token"
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
	chain := CallChain{Function: targetFunc}
	fileInfos, err := parseFiles(files)
	if err != nil {
		return chain, err
	}

	visited := make(map[string]bool)
	analyzeCallChainRecursive(&chain, fileInfos, visited, maxDepth)

	return chain, nil
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

func analyzeCallChainRecursive(chain *CallChain, files []FileInfo, visited map[string]bool, depth int) {
	if depth == 0 {
		return
	}

	for _, file := range files {
		ast.Inspect(file.AST, func(n ast.Node) bool {
			if call, ok := n.(*ast.CallExpr); ok {
				if ident, ok := call.Fun.(*ast.Ident); ok && ident.Name == chain.Function {
					if funcDecl := findEnclosingFunction(file.AST, call); funcDecl != nil {
						callerName := funcDecl.Name.Name
						if !visited[callerName] {
							chain.Callers = append(chain.Callers, callerName)
							visited[callerName] = true
							subChain := &CallChain{Function: callerName}
							analyzeCallChainRecursive(subChain, files, visited, depth-1)
						}
					}
				}
			}
			return true
		})
	}
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
