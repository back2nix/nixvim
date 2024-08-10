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
	"path/filepath"
	"strings"

	"github.com/neovim/go-client/nvim"
	"golang.org/x/mod/modfile"
)

func main() {
	log.SetFlags(0)
	stdout := os.Stdout
	os.Stdout = os.Stderr

	v, err := nvim.New(os.Stdin, stdout, stdout, log.Printf)
	if err != nil {
		log.Fatal(err)
	}

	v.RegisterHandler("renameImport", renameImport)

	if err := v.Serve(); err != nil {
		log.Fatal(err)
	}
}

func renameImport(v *nvim.Nvim, args []string) (string, error) {
	if len(args) != 3 {
		return "", fmt.Errorf("expected 3 arguments: projectRoot, oldImport, newImport")
	}

	projectRoot := args[0]
	oldImport := args[1]
	newImport := args[2]

	// Определение имени модуля из go.mod
	moduleName, err := getModuleName(projectRoot)
	if err != nil {
		return "", fmt.Errorf("failed to get module name: %v", err)
	}

	// 1. Найти все Go файлы в проекте
	goFiles, err := findGoFiles(projectRoot)
	if err != nil {
		return "", fmt.Errorf("failed to find Go files: %v", err)
	}

	// 2. Обновить импорты во всех файлах
	for _, file := range goFiles {
		if err := updateImportsInFile(file, oldImport, newImport); err != nil {
			return "", fmt.Errorf("failed to update imports in %s: %v", file, err)
		}
	}

	// 3. Переименовать папку
	oldPath := filepath.Join(projectRoot, strings.TrimPrefix(oldImport, moduleName+"/"))
	newPath := filepath.Join(projectRoot, strings.TrimPrefix(newImport, moduleName+"/"))
	if err := os.Rename(oldPath, newPath); err != nil {
		return "", fmt.Errorf("failed to rename directory: %v", err)
	}

	// 4. Обновить объявления пакетов в переименованной папке
	newPackageName := filepath.Base(newPath)
	if err := updatePackageDeclarations(newPath, newPackageName); err != nil {
		return "", fmt.Errorf("failed to update package declarations: %v", err)
	}

	return "Import renamed successfully", nil
}

// getModuleName читает имя модуля из go.mod файла
func getModuleName(projectRoot string) (string, error) {
	modFile := filepath.Join(projectRoot, "go.mod")
	content, err := ioutil.ReadFile(modFile)
	if err != nil {
		return "", err
	}

	modName := modfile.ModulePath(content)
	if modName == "" {
		return "", fmt.Errorf("module name not found in go.mod")
	}

	return modName, nil
}

func findGoFiles(root string) ([]string, error) {
	var files []string
	err := filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if !info.IsDir() && strings.HasSuffix(path, ".go") {
			files = append(files, path)
		}
		return nil
	})
	return files, err
}

func updateImportsInFile(filePath, oldImport, newImport string) error {
	fset := token.NewFileSet()
	node, err := parser.ParseFile(fset, filePath, nil, parser.ParseComments)
	if err != nil {
		return err
	}

	var importChanged bool
	ast.Inspect(node, func(n ast.Node) bool {
		if imp, ok := n.(*ast.ImportSpec); ok {
			if imp.Path != nil && imp.Path.Value == `"`+oldImport+`"` {
				imp.Path.Value = `"` + newImport + `"`
				importChanged = true
			}
		}
		return true
	})

	if importChanged {
		var buf bytes.Buffer
		if err := format.Node(&buf, fset, node); err != nil {
			return err
		}
		return ioutil.WriteFile(filePath, buf.Bytes(), 0o644)
	}

	return nil
}

func updatePackageDeclarations(dirPath, newPackageName string) error {
	return filepath.Walk(dirPath, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if !info.IsDir() && strings.HasSuffix(path, ".go") {
			fset := token.NewFileSet()
			node, err := parser.ParseFile(fset, path, nil, parser.ParseComments)
			if err != nil {
				return err
			}

			if node.Name.Name != newPackageName {
				node.Name.Name = newPackageName

				var buf bytes.Buffer
				if err := format.Node(&buf, fset, node); err != nil {
					return err
				}
				return ioutil.WriteFile(path, buf.Bytes(), 0o644)
			}
		}
		return nil
	})
}

func init() {
	log.SetFlags(log.LstdFlags | log.Lshortfile)
	log.SetPrefix("golang-rename-import-plugin: ")
}
