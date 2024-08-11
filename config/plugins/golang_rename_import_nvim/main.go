package main

import (
	"bytes"
	"fmt"
	"go/ast"
	"go/format"
	"go/parser"
	"go/token"
	"io"
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

	// 1. Анализ старого и нового пути импорта
	oldRelPath := strings.TrimPrefix(oldImport, moduleName+"/")
	newRelPath := strings.TrimPrefix(newImport, moduleName+"/")
	oldPath := filepath.Join(projectRoot, oldRelPath)
	newPath := filepath.Join(projectRoot, newRelPath)

	// 2. Создание новой структуры директорий
	if err := os.MkdirAll(filepath.Dir(newPath), 0o755); err != nil {
		return "", fmt.Errorf("failed to create new directory structure: %v", err)
	}

	// 3. Перемещение файлов
	if err := moveFiles(oldPath, newPath); err != nil {
		return "", fmt.Errorf("failed to move files: %v", err)
	}

	// 4. Удаление пустых директорий
	if err := removeEmptyDirs(oldPath); err != nil {
		return "", fmt.Errorf("failed to remove empty directories: %v", err)
	}

	// 5. Обновление импортов и использования пакетов
	goFiles, err := findAllGoFiles(projectRoot)
	if err != nil {
		return "", fmt.Errorf("failed to find Go files: %v", err)
	}

	for _, file := range goFiles {
		if err := updateFileContent(file, oldImport, newImport); err != nil {
			return "", fmt.Errorf("failed to update content in %s: %v", file, err)
		}
	}

	// 6. Обновление объявлений пакетов
	newPackageName := filepath.Base(newPath)
	if err := updatePackageDeclarations(newPath, newPackageName); err != nil {
		return "", fmt.Errorf("failed to update package declarations: %v", err)
	}

	return "Import renamed successfully", nil
}

func moveFiles(oldPath, newPath string) error {
	return filepath.Walk(oldPath, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		relPath, err := filepath.Rel(oldPath, path)
		if err != nil {
			return err
		}

		newFilePath := filepath.Join(newPath, relPath)

		if info.IsDir() {
			return os.MkdirAll(newFilePath, info.Mode())
		}

		if err := os.MkdirAll(filepath.Dir(newFilePath), 0o755); err != nil {
			return err
		}

		return os.Rename(path, newFilePath)
	})
}

func removeEmptyDirs(dir string) error {
	return filepath.Walk(dir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		if info.IsDir() {
			// Проверяем, пуста ли директория
			empty, err := isDirEmpty(path)
			if err != nil {
				return err
			}

			if empty {
				if err := os.Remove(path); err != nil {
					return err
				}
				// Если директория удалена, пропускаем ее содержимое
				return filepath.SkipDir
			}
		}

		return nil
	})
}

func isDirEmpty(dir string) (bool, error) {
	f, err := os.Open(dir)
	if err != nil {
		return false, err
	}
	defer f.Close()

	_, err = f.Readdirnames(1)
	if err == io.EOF {
		return true, nil
	}
	return false, err
}

func findAllGoFiles(root string) ([]string, error) {
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

func updateFileContent(filePath, oldImport, newImport string) error {
	// Check if file exists and is not empty
	info, err := os.Stat(filePath)
	if err != nil {
		return fmt.Errorf("error accessing file %s: %v", filePath, err)
	}
	if info.Size() == 0 {
		log.Printf("Skipping empty file: %s", filePath)
		return nil // Skip empty files instead of returning an error
	}

	// Read file contents
	content, err := ioutil.ReadFile(filePath)
	if err != nil {
		return fmt.Errorf("error reading file %s: %v", filePath, err)
	}

	// Parse file
	fset := token.NewFileSet()
	node, err := parser.ParseFile(fset, filePath, content, parser.ParseComments)
	if err != nil {
		log.Printf("Error parsing file %s: %v\nFile contents:\n%s", filePath, err, string(content))
		return fmt.Errorf("error parsing file %s: %v", filePath, err)
	}

	var importChanged bool
	var oldPackageName, newPackageName string
	var hasAlias bool

	// Update imports and check for alias
	for _, imp := range node.Imports {
		if imp.Path != nil && imp.Path.Value == `"`+oldImport+`"` {
			imp.Path.Value = `"` + newImport + `"`
			importChanged = true
			oldPackageName = filepath.Base(oldImport)
			newPackageName = filepath.Base(newImport)
			hasAlias = imp.Name != nil
			break
		}
	}

	// Update package usage if import was changed and there's no alias
	if importChanged && !hasAlias {
		ast.Inspect(node, func(n ast.Node) bool {
			switch x := n.(type) {
			case *ast.SelectorExpr:
				if ident, ok := x.X.(*ast.Ident); ok {
					if ident.Name == oldPackageName {
						ident.Name = newPackageName
					}
				}
			}
			return true
		})
	}

	// Write changes back to file if imports or usage were changed
	if importChanged {
		var buf bytes.Buffer
		if err := format.Node(&buf, fset, node); err != nil {
			return fmt.Errorf("error formatting updated AST for %s: %v", filePath, err)
		}
		if err := ioutil.WriteFile(filePath, buf.Bytes(), 0o644); err != nil {
			return fmt.Errorf("error writing updated content to %s: %v", filePath, err)
		}
	}

	return nil
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
