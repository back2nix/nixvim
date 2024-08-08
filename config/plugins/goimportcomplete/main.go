package main

import (
	"bufio"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"sync"

	"github.com/neovim/go-client/nvim"
)

var (
	importPaths      []string
	importPathsMutex sync.RWMutex
)

func getModuleName(dir string) (string, error) {
	modFile, err := os.Open(filepath.Join(dir, "go.mod"))
	if err != nil {
		return "", err
	}
	defer modFile.Close()

	scanner := bufio.NewScanner(modFile)
	for scanner.Scan() {
		line := scanner.Text()
		if strings.HasPrefix(line, "module ") {
			return strings.TrimSpace(strings.TrimPrefix(line, "module ")), nil
		}
	}
	return "", os.ErrNotExist
}

func walkDir(dir, rootDir, moduleName string) (map[string]struct{}, error) {
	imports := make(map[string]struct{})
	err := filepath.Walk(dir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if filepath.Ext(path) == ".go" {
			relPath, err := filepath.Rel(rootDir, filepath.Dir(path))
			if err != nil {
				return err
			}
			importPath := fmt.Sprintf(`"%s"`, filepath.Join(moduleName, relPath))
			if importPath != moduleName { // Exclude the root module itself
				imports[importPath] = struct{}{}
			}
		}
		return nil
	})
	return imports, err
}

func completeImport(v *nvim.Nvim, args []string) ([]string, error) {
	wd, err := os.Getwd()
	if err != nil {
		return nil, err
	}

	moduleName, err := getModuleName(wd)
	if err != nil {
		return nil, err
	}

	importsMap, err := walkDir(wd, wd, moduleName)
	if err != nil {
		return nil, err
	}

	// Convert map to slice
	imports := make([]string, 0, len(importsMap))
	for imp := range importsMap {
		imports = append(imports, imp)
	}

	// Sort the imports
	sort.Strings(imports)

	return imports, nil
}

func main() {
	log.SetFlags(0)
	stdout := os.Stdout
	os.Stdout = os.Stderr

	v, err := nvim.New(os.Stdin, stdout, stdout, log.Printf)
	if err != nil {
		log.Fatal(err)
	}

	v.RegisterHandler("completeImport", completeImport)

	if err := v.Serve(); err != nil {
		log.Fatal(err)
	}
}
