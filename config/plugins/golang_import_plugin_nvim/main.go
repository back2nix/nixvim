package main

import (
	"fmt"
	"go/parser"
	"go/token"
	"log"
	"os"
	"path/filepath"
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

	v.RegisterHandler("addImport", addImport)

	if err := v.Serve(); err != nil {
		log.Fatal(err)
	}
}

func findAliases(projectRoot string) (map[string]string, error) {
	aliases := make(map[string]string)

	err := filepath.Walk(projectRoot, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if !info.IsDir() && strings.HasSuffix(path, ".go") {
			processFile(path, aliases)
		}
		return nil
	})
	if err != nil {
		return nil, fmt.Errorf("error walking the path %v: %v", projectRoot, err)
	}

	return aliases, nil
}

func processFile(filePath string, aliases map[string]string) {
	fset := token.NewFileSet()
	node, err := parser.ParseFile(fset, filePath, nil, parser.ImportsOnly)
	if err != nil {
		fmt.Printf("Error parsing file %s: %v\n", filePath, err)
		return
	}

	for _, i := range node.Imports {
		importPath := strings.Trim(i.Path.Value, "\"")
		if i.Name != nil {
			// Импорт с явным псевдонимом
			alias := i.Name.Name
			aliases[alias] = importPath
		} else {
			// Импорт без псевдонима
			parts := strings.Split(importPath, "/")
			alias := parts[len(parts)-1]
			aliases[alias] = importPath
		}
	}
}

func addImport(v *nvim.Nvim, args []string) (string, error) {
	if len(args) < 2 {
		return "", fmt.Errorf("insufficient arguments: need word and project root")
	}
	word := args[0]

	// Получаем текущий буфер
	buf, err := v.CurrentBuffer()
	if err != nil {
		return "", fmt.Errorf("ошибка при получении текущего буфера: %v", err)
	}

	// Получаем имя файла для текущего буфера
	filename, err := v.BufferName(buf)
	if err != nil {
		return "", fmt.Errorf("ошибка при получении имени файла: %v", err)
	}

	// Определяем корень проекта
	projectRoot := findProjectRoot(filepath.Dir(filename))
	if projectRoot == "" {
		return "", fmt.Errorf("не удалось определить корень проекта для файла %s", filename)
	}

	// Find all aliases in the project
	aliases, err := findAliases(projectRoot)
	if err != nil {
		return "", err
	}

	// Check if the word matches any alias
	importPath, found := aliases[word]
	if !found {
		return "", fmt.Errorf("no import found for alias: %s", word)
	}

	// Get the current buffer
	b, err := v.CurrentBuffer()
	if err != nil {
		return "", err
	}

	// Get all lines from the buffer
	lines, err := v.BufferLines(b, 0, -1, true)
	if err != nil {
		return "", err
	}

	importStr := fmt.Sprintf(`"%s"`, importPath)
	aliasStr := ""
	if word != filepath.Base(importPath) {
		aliasStr = word + " "
	}
	fullImportStr := fmt.Sprintf("\t%s%s", aliasStr, importStr)

	importFound := false
	importBlockStart := -1
	importBlockEnd := -1

	// Find the import block
	for i, line := range lines {
		if strings.HasPrefix(string(line), "import (") {
			importBlockStart = i
		} else if importBlockStart != -1 && strings.HasPrefix(string(line), ")") {
			importBlockEnd = i
			break
		}
	}

	// If import block found, check if our import already exists
	if importBlockStart != -1 && importBlockEnd != -1 {
		for i := importBlockStart + 1; i < importBlockEnd; i++ {
			if strings.TrimSpace(string(lines[i])) == strings.TrimSpace(fullImportStr) {
				importFound = true
				break
			}
		}
	}

	// If import not found, add it
	if !importFound {
		if importBlockStart != -1 && importBlockEnd != -1 {
			// Insert into existing import block
			newLines := append(lines[:importBlockEnd], append([][]byte{[]byte(fullImportStr)}, lines[importBlockEnd:]...)...)
			err = v.SetBufferLines(b, 0, -1, true, newLines)
		} else {
			// Create new import block at the top of the file
			newImportBlock := [][]byte{
				[]byte("import ("),
				[]byte(fullImportStr),
				[]byte(")"),
				[]byte(""),
			}
			newLines := append(newImportBlock, lines...)
			err = v.SetBufferLines(b, 0, -1, true, newLines)
		}
		if err != nil {
			return "", err
		}
	}

	return "", nil
}

func findProjectRoot(dir string) string {
	for {
		if _, err := os.Stat(filepath.Join(dir, "go.mod")); err == nil {
			return dir
		}
		if _, err := os.Stat(filepath.Join(dir, ".git")); err == nil {
			return dir
		}
		parent := filepath.Dir(dir)
		if parent == dir {
			return ""
		}
		dir = parent
	}
}
