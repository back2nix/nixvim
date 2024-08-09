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
	"time"

	"github.com/neovim/go-client/nvim"
)

var (
	importPaths      []string
	importPathsMutex sync.RWMutex
)

func findProjectRoot(dir string) (string, error) {
	for {
		if _, err := os.Stat(filepath.Join(dir, "go.mod")); err == nil {
			return dir, nil
		}
		parent := filepath.Dir(dir)
		if parent == dir {
			return "", fmt.Errorf("go.mod not found in any parent directory")
		}
		dir = parent
	}
}

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
			if importPath != fmt.Sprintf(`"%s"`, moduleName) { // Exclude the root module itself
				imports[importPath] = struct{}{}
			}
		}
		return nil
	})
	return imports, err
}

var (
	cache     []string
	cacheTime time.Time
	cacheMu   sync.Mutex
)

func completeImport(v *nvim.Nvim, args []string) ([]string, error) {
	cacheMu.Lock()
	defer cacheMu.Unlock()

	// Check if cache is still valid
	if time.Since(cacheTime) < 60*time.Second && cache != nil {
		return cache, nil
	}

	// If cache is invalid or empty, compute the result
	wd, err := os.Getwd()
	if err != nil {
		return nil, err
	}

	projectRoot, err := findProjectRoot(wd)
	if err != nil {
		return nil, err
	}

	moduleName, err := getModuleName(projectRoot)
	if err != nil {
		return nil, err
	}

	importsMap, err := walkDir(projectRoot, projectRoot, moduleName)
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

	// Update cache
	cache = imports
	cacheTime = time.Now()

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
