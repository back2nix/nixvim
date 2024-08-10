package main

import (
	"bytes"
	"fmt"
	"go/ast"
	"go/format"
	"go/parser"
	"go/token"
	"io/ioutil"
	"log"
	"os"
	"strings"

	"github.com/neovim/go-client/nvim"
)

func main() {
	log.SetFlags(0)
	stdout := os.Stdout
	os.Stdout = os.Stderr

	v, err := nvim.New(os.Stdin, stdout, stdout, log.Printf)
	if err != nil {
		log.Fatal(err)
	}

	v.RegisterHandler("renameAlias", renameAlias)
	v.RegisterHandler("getImportOrAliasUnderCursor", getImportOrAliasUnderCursor)

	if err := v.Serve(); err != nil {
		log.Fatal(err)
	}
}

func renameAlias(v *nvim.Nvim, args []string) (string, error) {
	if len(args) != 3 {
		return "", fmt.Errorf("expected 3 arguments: filePath, oldAlias, newAlias")
	}

	filePath := args[0]
	oldAlias := args[1]
	newAlias := args[2]

	if err := updateFileAlias(filePath, oldAlias, newAlias); err != nil {
		return "", fmt.Errorf("failed to rename alias in %s: %v", filePath, err)
	}

	return "Alias renamed successfully", nil
}

func getImportOrAliasUnderCursor(v *nvim.Nvim, args []string) (map[string]interface{}, error) {
	if len(args) != 1 {
		return nil, fmt.Errorf("expected 1 argument: filePath")
	}

	filePath := args[0]

	_, err := v.CurrentBuffer()
	if err != nil {
		return nil, fmt.Errorf("failed to get current buffer: %v", err)
	}

	w, err := v.CurrentWindow()
	if err != nil {
		return nil, fmt.Errorf("failed to get current window: %v", err)
	}

	cursor, err := v.WindowCursor(w)
	if err != nil {
		return nil, fmt.Errorf("failed to get cursor position: %v", err)
	}

	row := cursor[0]

	fset := token.NewFileSet()
	node, err := parser.ParseFile(fset, filePath, nil, parser.ParseComments)
	if err != nil {
		return nil, fmt.Errorf("failed to parse file: %v", err)
	}

	for _, imp := range node.Imports {
		impPos := fset.Position(imp.Pos())
		impEndPos := fset.Position(imp.End())

		if impPos.Line <= int(row) && int(row) <= impEndPos.Line {
			if imp.Name != nil {
				// This is an aliased import
				return map[string]interface{}{
					"value": imp.Name.Name,
					"kind":  "alias",
				}, nil
			} else {
				// This is a regular import
				importPath := strings.Trim(imp.Path.Value, `"`)
				return map[string]interface{}{
					"value": importPath,
					"kind":  "import",
				}, nil
			}
		}
	}

	return nil, nil
}

func updateFileAlias(filePath, oldAlias, newAlias string) error {
	fset := token.NewFileSet()
	node, err := parser.ParseFile(fset, filePath, nil, parser.ParseComments)
	if err != nil {
		return err
	}

	var aliasChanged bool

	// First, find and update the import statement
	for _, imp := range node.Imports {
		if imp.Name != nil && imp.Name.Name == oldAlias {
			imp.Name.Name = newAlias
			aliasChanged = true
			break
		}
	}

	if aliasChanged {
		// Then, update all usages of the alias in the file
		ast.Inspect(node, func(n ast.Node) bool {
			switch x := n.(type) {
			case *ast.SelectorExpr:
				if ident, ok := x.X.(*ast.Ident); ok && ident.Name == oldAlias {
					ident.Name = newAlias
				}
			case *ast.Ident:
				// Update simple identifiers that match the old alias
				if x.Name == oldAlias {
					x.Name = newAlias
				}
			}
			return true
		})

		var buf bytes.Buffer
		if err := format.Node(&buf, fset, node); err != nil {
			return err
		}
		return ioutil.WriteFile(filePath, buf.Bytes(), 0o644)
	}

	return nil
}

func init() {
	log.SetFlags(log.LstdFlags | log.Lshortfile)
	log.SetPrefix("golang-rename-import-plugin: ")
}
