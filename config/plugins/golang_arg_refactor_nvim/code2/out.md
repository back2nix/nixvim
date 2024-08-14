File: cmd/main.go
```
package main

import (
	"fmt"
	"go/ast"
	"go/printer"
	"go/token"
	"log"
	"os"

	"github.com/back2nix/go-arg-propagation/pkg/analyzer"
	"github.com/back2nix/go-arg-propagation/pkg/filemanager"
	"github.com/back2nix/go-arg-propagation/pkg/modifier"
	"github.com/back2nix/go-arg-propagation/pkg/parser"
	"github.com/back2nix/go-arg-propagation/pkg/traverser"
)

func main() {
	coordinator := NewMainCoordinator()
	functions := []string{
		"add",
	}

	argCounter := 1

	for _, funcName := range functions {
		argName := fmt.Sprintf("a%d", argCounter)
		err := coordinator.AddArgumentToFunction(
			"../code/main.go",
			funcName,
			argName,
			"int",
		)
		if err != nil {
			log.Fatalf("Error adding argument to %s: %v", funcName, err)
		}
		argCounter++
	}
}

type MainCoordinator struct {
	analyzer    *analyzer.CallChainAnalyzer
	parser      *parser.Parser
	fileManager *filemanager.FileManager
	traverser   *traverser.ASTTraverser
	funcDeclMod modifier.IFuncDeclModifier
	funcLitMod  modifier.IFuncLitModifier
	callExprMod modifier.ICallExprModifier
	fset        *token.FileSet
}

func NewMainCoordinator() *MainCoordinator {
	fset := token.NewFileSet()
	return &MainCoordinator{
		analyzer:    analyzer.NewCallChainAnalyzer(),
		parser:      parser.NewParser(),
		fileManager: filemanager.NewFileManager(),
		funcDeclMod: modifier.NewFuncDeclModifier(),
		funcLitMod:  modifier.NewFuncLitModifier(),
		callExprMod: modifier.NewCallExprModifier(nil, fset),
		fset:        fset,
	}
}

func (mc *MainCoordinator) AddArgumentToFunction(filePath, targetFunc, paramName, paramType string) error {
	log.Printf("Starting AddArgumentToFunction for %s in %s", targetFunc, filePath)

	// Step 1: Read the file
	src, err := mc.readFile(filePath)
	if err != nil {
		return fmt.Errorf("failed to read file: %w", err)
	}

	// Step 2: Analyze the call chain
	functionsToModify, err := mc.analyzeCallChain(src, targetFunc)
	if err != nil {
		return fmt.Errorf("failed to analyze call chain: %w", err)
	}
	log.Printf("Functions to modify: %v", functionsToModify)

	// Step 3: Parse the AST
	file, err := mc.parseAST(src)
	if err != nil {
		return fmt.Errorf("failed to parse AST: %w", err)
	}

	// Step 4: Set up the call expression modifier with the functions to modify
	mc.callExprMod = modifier.NewCallExprModifier(functionsToModify, mc.fset)

	// Step 5: Set up the traverser
	mc.traverser = traverser.NewASTTraverser(
		mc.parser,
		mc.funcDeclMod.(*modifier.FuncDeclModifier),
		mc.funcLitMod.(*modifier.FuncLitModifier),
		mc.callExprMod.(*modifier.CallExprModifier),
	)

	// Step 6: Traverse and modify the AST
	err = mc.traverseAndModifyAST(file, functionsToModify, paramName, paramType)
	if err != nil {
		return fmt.Errorf("failed to traverse and modify AST: %w", err)
	}

	// Step 7: Write the modified AST back to the file
	err = mc.writeModifiedAST(filePath, file)
	if err != nil {
		return fmt.Errorf("failed to write modified AST: %w", err)
	}

	log.Println("Successfully added argument to function and its call chain")
	return nil
}

func (mc *MainCoordinator) readFile(filePath string) ([]byte, error) {
	return mc.fileManager.ReadFile(filePath)
}

func (mc *MainCoordinator) analyzeCallChain(src []byte, targetFunc string) ([]string, error) {
	return mc.analyzer.AnalyzeCallChain(src, targetFunc)
}

func (mc *MainCoordinator) parseAST(src []byte) (*ast.File, error) {
	return mc.parser.Parse(src)
}

func (mc *MainCoordinator) traverseAndModifyAST(file *ast.File, functionsToModify []string, paramName, paramType string) error {
	return mc.traverser.Traverse(file, functionsToModify, paramName, paramType)
}

func (mc *MainCoordinator) writeModifiedAST(filePath string, file *ast.File) error {
	// Create a temporary file
	tmpFile, err := os.CreateTemp("", "modified_*.go")
	if err != nil {
		return fmt.Errorf("failed to create temporary file: %w", err)
	}
	defer tmpFile.Close()

	// Use the printer package to write the AST to the temporary file
	err = printer.Fprint(tmpFile, mc.fset, file)
	if err != nil {
		return fmt.Errorf("failed to write AST to temporary file: %w", err)
	}

	// Close the temporary file
	tmpFile.Close()

	// Read the contents of the temporary file
	content, err := os.ReadFile(tmpFile.Name())
	if err != nil {
		return fmt.Errorf("failed to read temporary file: %w", err)
	}

	// Write the contents to the original file
	err = mc.fileManager.WriteFile(filePath, content)
	if err != nil {
		return fmt.Errorf("failed to write to original file: %w", err)
	}

	// Remove the temporary file
	os.Remove(tmpFile.Name())

	return nil
}
```

File: pkg/analyzer/analyzer.go
```
package analyzer

import (
	"fmt"
	"go/ast"
	"go/parser"
	"go/token"
	"log"
)

// CallChainAnalyzer представляет анализатор цепочки вызовов
type CallChainAnalyzer struct {
	callGraph map[string][]string
	anonFuncs map[string]string
	fset      *token.FileSet
}

// NewCallChainAnalyzer создает новый экземпляр CallChainAnalyzer
func NewCallChainAnalyzer() *CallChainAnalyzer {
	return &CallChainAnalyzer{
		callGraph: make(map[string][]string),
		anonFuncs: make(map[string]string),
		fset:      token.NewFileSet(),
	}
}

// AnalyzeCallChain анализирует цепочку вызовов для заданной целевой функции
func (a *CallChainAnalyzer) AnalyzeCallChain(src []byte, targetFunc string) ([]string, error) {
	log.Printf("Starting analysis for target function: %s", targetFunc)

	file, err := parser.ParseFile(a.fset, "", src, parser.AllErrors)
	if err != nil {
		return nil, fmt.Errorf("failed to parse file: %w", err)
	}

	a.buildCallGraph(file)
	chain := a.findCallChain(targetFunc)

	log.Printf("Call chain for %s: %v", targetFunc, chain)
	return chain, nil
}

// buildCallGraph строит граф вызовов функций
func (a *CallChainAnalyzer) buildCallGraph(file *ast.File) {
	var currentFunc string

	ast.Inspect(file, func(n ast.Node) bool {
		switch x := n.(type) {
		case *ast.FuncDecl:
			currentFunc = x.Name.Name
			log.Printf("Analyzing function: %s", currentFunc)
			a.analyzeFuncBody(currentFunc, x.Body)
		case *ast.FuncLit:
			anonName := fmt.Sprintf("anonymous%p", x)
			a.anonFuncs[anonName] = currentFunc
			log.Printf("Analyzing anonymous function in %s: %s", currentFunc, anonName)
			a.analyzeFuncBody(anonName, x.Body)
		}
		return true
	})

	log.Printf("Call graph: %v", a.callGraph)
	log.Printf("Anonymous functions: %v", a.anonFuncs)
}

// analyzeFuncBody анализирует тело функции на наличие вызовов других функций
func (a *CallChainAnalyzer) analyzeFuncBody(funcName string, body *ast.BlockStmt) {
	if body == nil {
		return
	}

	ast.Inspect(body, func(n ast.Node) bool {
		if call, ok := n.(*ast.CallExpr); ok {
			switch fun := call.Fun.(type) {
			case *ast.Ident:
				callee := fun.Name
				a.callGraph[callee] = append(a.callGraph[callee], funcName)
				log.Printf("Found call from %s to %s", funcName, callee)
			case *ast.SelectorExpr:
				if x, ok := fun.X.(*ast.Ident); ok {
					callee := fmt.Sprintf("%s.%s", x.Name, fun.Sel.Name)
					a.callGraph[callee] = append(a.callGraph[callee], funcName)
					log.Printf("Found call from %s to %s", funcName, callee)
				}
			}
		}
		return true
	})
}

// findCallChain находит цепочку вызовов для целевой функции
func (a *CallChainAnalyzer) findCallChain(targetFunc string) []string {
	visited := make(map[string]bool)
	var chain []string

	var dfs func(string)
	dfs = func(current string) {
		if visited[current] {
			return
		}
		visited[current] = true
		chain = append(chain, current)
		log.Printf("Added %s to call chain", current)

		for caller, callees := range a.callGraph {
			for _, callee := range callees {
				if callee == current {
					dfs(caller)
				}
			}
		}
		if parent, ok := a.anonFuncs[current]; ok {
			dfs(parent)
		}
	}

	dfs(targetFunc)
	return chain
}
```

File: pkg/analyzer/analyzer_test.go
```
package analyzer

import (
	"strings"
	"testing"
)

func TestAnalyzeCallChain(t *testing.T) {
	src := `
package main

func main() {
	foo()
}

func foo() {
	bar()
	func() {
	func() {
		baz()
	}()
	}()
}

func bar() {
	// Пустая функция
}

func baz() {
	// Целевая функция
}

func unused() {
	// Эта функция не должна попасть в цепочку вызовов
}
`

	analyzer := NewCallChainAnalyzer()
	chain, err := analyzer.AnalyzeCallChain([]byte(src), "baz")
	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}

	// Проверяем, что цепочка содержит ожидаемые элементы в правильном порядке
	expected := []string{"baz", "foo", "main", "anonymous", "anonymous"}
	if len(chain) != len(expected) {
		t.Errorf("Expected chain length %d, but got %d\n%v -> %v", len(expected), len(chain), expected, chain)
	} else {
		for i, funcName := range chain {
			if !strings.HasPrefix(funcName, expected[i]) {
				t.Errorf("At position expected %s, but got %s", expected, chain)
				break
			}
		}
	}
}
```

File: pkg/filemanager/filemanager.go
```
package filemanager

import (
	"io/ioutil"
	"os"
	"path/filepath"
)

type FileManager struct{}

func NewFileManager() *FileManager {
	return &FileManager{}
}

func (fm *FileManager) ReadFile(filePath string) ([]byte, error) {
	return ioutil.ReadFile(filePath)
}

func (fm *FileManager) WriteFile(filePath string, content []byte) error {
	return ioutil.WriteFile(filePath, content, 0o644)
}

func (fm *FileManager) CreateFile(filePath string, content []byte) error {
	if fm.FileExists(filePath) {
		return os.ErrExist
	}
	return fm.WriteFile(filePath, content)
}

func (fm *FileManager) FileExists(filePath string) bool {
	_, err := os.Stat(filePath)
	return !os.IsNotExist(err)
}

func (fm *FileManager) GetGoFiles(dirPath string) ([]string, error) {
	var goFiles []string
	err := filepath.Walk(dirPath, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if !info.IsDir() && filepath.Ext(path) == ".go" {
			goFiles = append(goFiles, path)
		}
		return nil
	})
	return goFiles, err
}
```

File: pkg/filemanager/filemanager_test.go
```
package filemanager

import (
	"io/ioutil"
	"os"
	"path/filepath"
	"testing"
)

func TestFileManager(t *testing.T) {
	tempDir, err := ioutil.TempDir("", "filemanager_test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	fm := NewFileManager()

	t.Run("ReadFile", func(t *testing.T) {
		content := []byte("test content")
		filePath := filepath.Join(tempDir, "test.txt")
		err := ioutil.WriteFile(filePath, content, 0o644)
		if err != nil {
			t.Fatalf("Failed to write test file: %v", err)
		}

		readContent, err := fm.ReadFile(filePath)
		if err != nil {
			t.Fatalf("ReadFile failed: %v", err)
		}
		if string(readContent) != string(content) {
			t.Errorf("ReadFile content mismatch. Got %s, want %s", string(readContent), string(content))
		}

		_, err = fm.ReadFile("non_existent_file.txt")
		if err == nil {
			t.Error("ReadFile should fail for non-existent file")
		}
	})

	t.Run("WriteFile", func(t *testing.T) {
		content := []byte("new content")
		filePath := filepath.Join(tempDir, "write_test.txt")

		err := fm.WriteFile(filePath, content)
		if err != nil {
			t.Fatalf("WriteFile failed: %v", err)
		}

		readContent, err := ioutil.ReadFile(filePath)
		if err != nil {
			t.Fatalf("Failed to read written file: %v", err)
		}
		if string(readContent) != string(content) {
			t.Errorf("WriteFile content mismatch. Got %s, want %s", string(readContent), string(content))
		}
	})

	t.Run("CreateFile", func(t *testing.T) {
		content := []byte("created content")
		filePath := filepath.Join(tempDir, "create_test.txt")

		err := fm.CreateFile(filePath, content)
		if err != nil {
			t.Fatalf("CreateFile failed: %v", err)
		}

		readContent, err := ioutil.ReadFile(filePath)
		if err != nil {
			t.Fatalf("Failed to read created file: %v", err)
		}
		if string(readContent) != string(content) {
			t.Errorf("CreateFile content mismatch. Got %s, want %s", string(readContent), string(content))
		}

		err = fm.CreateFile(filePath, content)
		if err == nil {
			t.Error("CreateFile should fail for existing file")
		}
	})

	t.Run("FileExists", func(t *testing.T) {
		existingFile := filepath.Join(tempDir, "existing.txt")
		err := ioutil.WriteFile(existingFile, []byte(""), 0o644)
		if err != nil {
			t.Fatalf("Failed to create test file: %v", err)
		}

		if !fm.FileExists(existingFile) {
			t.Error("FileExists should return true for existing file")
		}

		if fm.FileExists("non_existent_file.txt") {
			t.Error("FileExists should return false for non-existent file")
		}
	})

	t.Run("GetGoFiles", func(t *testing.T) {
		goFile1 := filepath.Join(tempDir, "file1.go")
		goFile2 := filepath.Join(tempDir, "file2.go")
		nonGoFile := filepath.Join(tempDir, "file.txt")

		files := []string{goFile1, goFile2, nonGoFile}
		for _, file := range files {
			err := ioutil.WriteFile(file, []byte(""), 0o644)
			if err != nil {
				t.Fatalf("Failed to create test file: %v", err)
			}
		}

		goFiles, err := fm.GetGoFiles(tempDir)
		if err != nil {
			t.Fatalf("GetGoFiles failed: %v", err)
		}

		if len(goFiles) != 2 {
			t.Errorf("GetGoFiles returned wrong number of files. Got %d, want 2", len(goFiles))
		}

		for _, file := range goFiles {
			if filepath.Ext(file) != ".go" {
				t.Errorf("GetGoFiles returned non-Go file: %s", file)
			}
		}
	})
}
```

File: pkg/modifier/call_expr_modifier.go
```
package modifier

import (
	"fmt"
	"go/ast"
	"go/token"
	"log"
	"strings"
)

type CallExprModifier struct {
	functionsToModify map[string]struct{}
	initialArgCounts  map[string]int
	fset              *token.FileSet
}

func NewCallExprModifier(functionsToModify []string, fset *token.FileSet) *CallExprModifier {
	modifierMap := make(map[string]struct{})
	initialArgCounts := make(map[string]int)
	for _, funcName := range functionsToModify {
		modifierMap[funcName] = struct{}{}
		initialArgCounts[funcName] = -1
	}
	return &CallExprModifier{
		functionsToModify: modifierMap,
		initialArgCounts:  initialArgCounts,
		fset:              fset,
	}
}

func (m *CallExprModifier) AddArgument(node ast.Node, argName string) error {
	ast.Inspect(node, func(n ast.Node) bool {
		switch x := n.(type) {
		case *ast.CallExpr:
			log.Printf("Inspecting CallExpr: %v", x)
			m.modifyCallExpr(x, argName)
		case *ast.FuncLit:
			log.Printf("Inspecting FuncLit: %v", x)
			ast.Inspect(x.Body, func(n ast.Node) bool {
				if ce, ok := n.(*ast.CallExpr); ok {
					log.Printf("Inspecting nested CallExpr in FuncLit: %v", ce)
					m.modifyCallExpr(ce, argName)
				}
				return true
			})
		}
		return true
	})
	return nil
}

func (m *CallExprModifier) modifyCallExpr(callExpr *ast.CallExpr, argName string) {
	funcName, ok := m.extractFuncName(callExpr)
	if !ok {
		log.Printf("Could not extract function name from CallExpr: %v", callExpr)
		return
	}

	shortFuncName := m.getShortFuncName(funcName)

	if !m.ShouldModifyFunction(shortFuncName) {
		log.Printf("Skipping modification for function: %s", shortFuncName)
		return
	}

	log.Printf("Modifying CallExpr for function: %s", funcName)

	if m.initialArgCounts[shortFuncName] == -1 {
		m.initialArgCounts[shortFuncName] = len(callExpr.Args)
	}

	expectedArgCount := m.initialArgCounts[shortFuncName] + 1
	if len(callExpr.Args) >= expectedArgCount {
		log.Printf("Function %s already has expected number of arguments", funcName)
		return
	}

	newArg := &ast.Ident{Name: argName}
	callExpr.Args = append(callExpr.Args, newArg)
	log.Printf("Added argument '%s' to function call: %s", argName, funcName)
}

func (m *CallExprModifier) extractFuncName(callExpr *ast.CallExpr) (string, bool) {
	switch fun := callExpr.Fun.(type) {
	case *ast.Ident:
		return fun.Name, true
	case *ast.SelectorExpr:
		if x, ok := fun.X.(*ast.Ident); ok {
			return fmt.Sprintf("%s.%s", x.Name, fun.Sel.Name), true
		}
	case *ast.CallExpr:
		// Обработка вызовов вида f()()
		if innerName, ok := m.extractFuncName(fun); ok {
			return innerName + "()", true
		}
	}
	return "", false
}

func (m *CallExprModifier) getShortFuncName(funcName string) string {
	parts := strings.Split(funcName, ".")
	return parts[len(parts)-1]
}

func (m *CallExprModifier) ShouldModifyFunction(funcName string) bool {
	_, shouldModify := m.functionsToModify[funcName]
	return shouldModify
}

func (m *CallExprModifier) UpdateFunctionDeclarations(
	file *ast.File,
	paramName, paramType string,
	funcDeclMod *FuncDeclModifier,
) error {
	for _, decl := range file.Decls {
		if funcDecl, ok := decl.(*ast.FuncDecl); ok {
			if m.ShouldModifyFunction(funcDecl.Name.Name) {
				err := funcDeclMod.AddParameter(funcDecl, paramName, paramType)
				if err != nil {
					return fmt.Errorf("failed to update function declaration %s: %w", funcDecl.Name.Name, err)
				}
			}
		}
	}
	return nil
}
```

File: pkg/modifier/call_expr_modifier_test.go
```
package modifier

import (
	"bytes"
	"go/ast"
	"go/parser"
	"go/printer"
	"go/token"
	"strings"
	"testing"

	"github.com/sergi/go-diff/diffmatchpatch"
)

func TestCallExprModifier_AddArgument(t *testing.T) {
	tests := []struct {
		name              string
		code              string
		functionsToModify []string
		argName           string
		expectedCode      string
	}{
		{
			name: "Don't modify already modified call",
			code: `package main
func main() {
    foo(existingArg)
    foo(anotherArg)
}`,
			functionsToModify: []string{"foo"},
			argName:           "newArg",
			expectedCode: `package main
func main() {
    foo(existingArg, newArg)
    foo(anotherArg, newArg)
}`,
		},
		{
			name: "Modify simple function call",
			code: `package main
func main() {
    foo()
}`,
			functionsToModify: []string{"foo"},
			argName:           "newArg",
			expectedCode: `package main
func main() {
    foo(newArg)
}`,
		},
		{
			name: "Don't modify unrelated function call",
			code: `package main
func main() {
    bar()
}`,
			functionsToModify: []string{"foo"},
			argName:           "newArg",
			expectedCode: `package main
func main() {
    bar()
}`,
		},
		{
			name: "Modify method call",
			code: `package main
func main() {
    obj.Method()
}`,
			functionsToModify: []string{"obj.Method"},
			argName:           "newArg",
			expectedCode: `package main
func main() {
    obj.Method(newArg)
}`,
		},
		{
			name: "Modify variadic function call",
			code: `package main
func main() {
    variadicFunc("a", "b")
}`,
			functionsToModify: []string{"variadicFunc"},
			argName:           "newArg",
			expectedCode: `package main
func main() {
    variadicFunc("a", "b", newArg)
}`,
		},
		{
			name: "Modify multiple calls in one function",
			code: `package main
func main() {
    foo()
    bar()
    foo()
}`,
			functionsToModify: []string{"foo"},
			argName:           "newArg",
			expectedCode: `package main
func main() {
    foo(newArg)
    bar()
    foo(newArg)
}`,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			fset := token.NewFileSet()
			file, err := parser.ParseFile(fset, "", tt.code, parser.ParseComments)
			if err != nil {
				t.Fatalf("Failed to parse code: %v", err)
			}

			modifier := NewCallExprModifier(tt.functionsToModify)

			ast.Inspect(file, func(n ast.Node) bool {
				if callExpr, ok := n.(*ast.CallExpr); ok {
					err := modifier.AddArgument(callExpr, tt.argName)
					if err != nil {
						t.Fatalf("AddArgument failed: %v", err)
					}
				}
				return true
			})

			var buf bytes.Buffer
			err = printer.Fprint(&buf, fset, file)
			if err != nil {
				t.Fatalf("Failed to print modified AST: %v", err)
			}

			got := normalizeWhitespace(buf.String())
			want := normalizeWhitespace(tt.expectedCode)

			if got != want {
				t.Errorf("Modified code does not match expected.\nGot:\n%s\nWant:\n%s\nDiff:\n%s", got, want, diff(want, got))
			}
		})
	}
}

func diff(expected, actual string) string {
	dmp := diffmatchpatch.New()
	diffs := dmp.DiffMain(expected, actual, false)
	return dmp.DiffPrettyText(diffs)
}

// astToString converts an AST to a string representation of the code
func astToString(fset *token.FileSet, node ast.Node) string {
	var buf strings.Builder
	err := printer.Fprint(&buf, fset, node)
	if err != nil {
		return ""
	}
	return buf.String()
}

// normalizeWhitespace removes leading and trailing whitespace from each line,
// ensures consistent newline characters, and trims the final newline
func normalizeWhitespace(s string) string {
	lines := strings.Split(s, "\n")
	var result []string
	for _, line := range lines {
		trimmed := strings.TrimSpace(line)
		if trimmed != "" {
			result = append(result, trimmed)
		}
	}
	return strings.Join(result, "\n")
}
```

File: pkg/modifier/func_decl_modifier.go
```
package modifier

import (
	"fmt"
	"go/ast"
)

type FuncDeclModifier struct {
	ModifiedFuncs map[string]bool
}

func NewFuncDeclModifier() *FuncDeclModifier {
	return &FuncDeclModifier{
		ModifiedFuncs: make(map[string]bool),
	}
}

func (m *FuncDeclModifier) AddParameter(funcDecl *ast.FuncDecl, paramName, paramType string) error {
	// Check if parameter already exists
	if m.parameterExists(funcDecl, paramName) {
		return fmt.Errorf("parameter %s already exists in function %s", paramName, funcDecl.Name.Name)
	}

	newParam := &ast.Field{
		Names: []*ast.Ident{ast.NewIdent(paramName)},
		Type:  ast.NewIdent(paramType),
	}

	if funcDecl.Type.Params == nil {
		funcDecl.Type.Params = &ast.FieldList{}
	}

	params := funcDecl.Type.Params.List
	if len(params) > 0 && isVariadic(params[len(params)-1]) {
		// If the last parameter is variadic, add the new parameter before it
		newParams := make([]*ast.Field, 0, len(params)+1)
		newParams = append(newParams, params[:len(params)-1]...)
		newParams = append(newParams, newParam)
		newParams = append(newParams, params[len(params)-1])
		funcDecl.Type.Params.List = newParams
	} else {
		// Add the new parameter at the end
		funcDecl.Type.Params.List = append(params, newParam)
	}

	// Modify function body
	if funcDecl.Body != nil {
		m.modifyFunctionBody(funcDecl.Body, paramName)
	}

	m.ModifiedFuncs[funcDecl.Name.Name] = true
	return nil
}

func (m *FuncDeclModifier) parameterExists(funcDecl *ast.FuncDecl, paramName string) bool {
	if funcDecl.Type.Params != nil {
		for _, field := range funcDecl.Type.Params.List {
			for _, name := range field.Names {
				if name.Name == paramName {
					return true
				}
			}
		}
	}
	return false
}

func (m *FuncDeclModifier) modifyFunctionBody(body *ast.BlockStmt, newParamName string) {
	ast.Inspect(body, func(n ast.Node) bool {
		if returnStmt, ok := n.(*ast.ReturnStmt); ok {
			for i, expr := range returnStmt.Results {
				if call, ok := expr.(*ast.CallExpr); ok {
					if ident, ok := call.Fun.(*ast.Ident); ok {
						if m.ModifiedFuncs[ident.Name] {
							call.Args = append(call.Args, ast.NewIdent(newParamName))
							returnStmt.Results[i] = call
						}
					}
				}
			}
		}
		return true
	})
}

func isVariadic(field *ast.Field) bool {
	_, ok := field.Type.(*ast.Ellipsis)
	return ok
}
```

File: pkg/modifier/func_decl_modifier_test.go
```
package modifier

import (
	"fmt"
	"go/ast"
	"go/parser"
	"go/token"
	"strings"
	"testing"
)

func TestFuncDeclModifier_AddParameter(t *testing.T) {
	tests := []struct {
		name     string
		input    string
		expected string
	}{
		{
			name:     "Add parameter to function with no parameters",
			input:    "func test() {}",
			expected: "func test(newParam int) {}",
		},
		{
			name:     "Add parameter to function with existing parameters",
			input:    "func test(a string) {}",
			expected: "func test(a string, newParam int) {}",
		},
		{
			name:     "Add parameter to variadic function",
			input:    "func test(a ...string) {}",
			expected: "func test(newParam int, a ...string) {}",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			fset := token.NewFileSet()
			node, err := parser.ParseFile(fset, "", "package main\n"+tt.input, parser.ParseComments)
			if err != nil {
				t.Fatalf("Failed to parse input: %v", err)
			}

			funcDecl := node.Decls[0].(*ast.FuncDecl)
			modifier := NewFuncDeclModifier()
			modifier.AddParameter(funcDecl, "newParam", "int")

			got := formatFuncDecl(funcDecl)
			if got != tt.expected {
				t.Errorf("AddParameter() =\n%v\nwant:\n%v", got, tt.expected)
			}
		})
	}
}

func formatFuncDecl(funcDecl *ast.FuncDecl) string {
	var params []string
	for _, p := range funcDecl.Type.Params.List {
		param := ""
		if len(p.Names) > 0 {
			param += p.Names[0].Name + " "
		}
		switch t := p.Type.(type) {
		case *ast.Ident:
			param += t.Name
		case *ast.Ellipsis:
			param += "..." + t.Elt.(*ast.Ident).Name
		}
		params = append(params, param)
	}

	return fmt.Sprintf("func %s(%s) {}", funcDecl.Name.Name, strings.Join(params, ", "))
}
```

File: pkg/modifier/func_lit_modifier.go
```
package modifier

import (
	"errors"
	"go/ast"
)

type FuncLitModifier struct {
	ModifiedFuncs map[string]bool
}

func NewFuncLitModifier() *FuncLitModifier {
	return &FuncLitModifier{
		ModifiedFuncs: make(map[string]bool),
	}
}

func (m *FuncLitModifier) AddParameter(funcLit *ast.FuncLit, paramName, paramType string, parentFuncName string) error {
	if funcLit == nil {
		return errors.New("funcLit is nil")
	}
	if paramName == "" || paramType == "" {
		return errors.New("paramName and paramType must not be empty")
	}

	// Check if we should modify this function literal based on its parent function
	if !m.ModifiedFuncs[parentFuncName] {
		return nil
	}

	// Check if the parameter already exists
	for _, field := range funcLit.Type.Params.List {
		for _, ident := range field.Names {
			if ident.Name == paramName {
				return nil // Parameter already exists, no modification needed
			}
		}
	}

	// Create new parameter
	newParam := &ast.Field{
		Names: []*ast.Ident{ast.NewIdent(paramName)},
		Type:  ast.NewIdent(paramType),
	}

	// Add new parameter to the function's parameter list
	funcLit.Type.Params.List = append(funcLit.Type.Params.List, newParam)

	// Modify function body to use the new parameter
	m.modifyFunctionBody(funcLit.Body, paramName)

	return nil
}

func (m *FuncLitModifier) modifyFunctionBody(body *ast.BlockStmt, newParamName string) {
	ast.Inspect(body, func(n ast.Node) bool {
		if returnStmt, ok := n.(*ast.ReturnStmt); ok {
			for i, expr := range returnStmt.Results {
				if call, ok := expr.(*ast.CallExpr); ok {
					if ident, ok := call.Fun.(*ast.Ident); ok {
						if m.ModifiedFuncs[ident.Name] {
							call.Args = append(call.Args, ast.NewIdent(newParamName))
							returnStmt.Results[i] = call
						}
					}
				}
			}
		}
		return true
	})
}
```

File: pkg/modifier/func_lit_modifier_test.go
```
package modifier

import (
	"go/ast"
	"go/parser"
	"go/printer"
	"go/token"
	"strings"
	"testing"
)

func TestFuncLitModifier_AddParameter(t *testing.T) {
	modifier := NewFuncLitModifier()

	tests := []struct {
		name        string
		input       string
		paramName   string
		paramType   string
		expected    string
		expectError bool
	}{
		{
			name:      "Add parameter to empty function",
			input:     "func() {}",
			paramName: "x",
			paramType: "int",
			expected:  "func(x int) {}",
		},
		{
			name:      "Add parameter to function with existing parameters",
			input:     "func(a string) {}",
			paramName: "x",
			paramType: "int",
			expected:  "func(a string, x int) {}",
		},
		{
			name:      "Add duplicate parameter (no change)",
			input:     "func(x int) {}",
			paramName: "x",
			paramType: "int",
			expected:  "func(x int) {}",
		},
		{
			name:        "Invalid input - nil FuncLit",
			input:       "",
			paramName:   "x",
			paramType:   "int",
			expectError: true,
		},
		{
			name:        "Invalid input - empty parameter name",
			input:       "func() {}",
			paramName:   "",
			paramType:   "int",
			expectError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			var funcLit *ast.FuncLit
			if tt.input != "" {
				expr, _ := parser.ParseExpr(tt.input)
				funcLit = expr.(*ast.FuncLit)
			}

			err := modifier.AddParameter(funcLit, tt.paramName, tt.paramType)

			if tt.expectError {
				if err == nil {
					t.Errorf("Expected an error, but got nil")
				}
			} else {
				if err != nil {
					t.Errorf("Unexpected error: %v", err)
				}

				result := exprToString(funcLit)
				if result != tt.expected {
					t.Errorf("Expected %q, but got %q", tt.expected, result)
				}
			}
		})
	}
}

// exprToString converts an AST expression to a string, removing newlines within function bodies
func exprToString(expr ast.Expr) string {
	if expr == nil {
		return ""
	}

	var buf strings.Builder
	fset := token.NewFileSet()

	err := printer.Fprint(&buf, fset, expr)
	if err != nil {
		return ""
	}

	// Remove newlines within function bodies
	result := buf.String()
	result = strings.ReplaceAll(result, "{\n}", "{}")
	result = strings.ReplaceAll(result, "{ }", "{}")

	return result
}

// Additional helper function to parse a string into an AST expression
func parseExpr(s string) (ast.Expr, error) {
	return parser.ParseExpr(s)
}
```

File: pkg/modifier/interfaces.go
```
package modifier

import (
	"go/ast"
)

type IFuncDeclModifier interface {
	AddParameter(funcDecl *ast.FuncDecl, paramName, paramType string) error
}

type IFuncLitModifier interface {
	AddParameter(funcLit *ast.FuncLit, paramName, paramType string, parentFuncName string) error
}

type ICallExprModifier interface {
	AddArgument(node ast.Node, argName string) error
	ShouldModifyFunction(funcName string) bool
	UpdateFunctionDeclarations(file *ast.File, paramName, paramType string, funcDeclMod *FuncDeclModifier) error
}
```

File: pkg/parser/parser.go
```
package parser

import (
	"go/ast"
	"go/parser"
	"go/token"
)

// Parser represents an AST parser
type Parser struct {
	fset *token.FileSet
}

// NewParser creates a new Parser instance
func NewParser() *Parser {
	return &Parser{
		fset: token.NewFileSet(),
	}
}

// Parse parses the source code and returns the AST
func (p *Parser) Parse(src []byte) (*ast.File, error) {
	return parser.ParseFile(p.fset, "", src, parser.ParseComments)
}

// GetFuncDecl finds a specific function declaration in the AST
func (p *Parser) GetFuncDecl(file *ast.File, funcName string) *ast.FuncDecl {
	for _, decl := range file.Decls {
		if fn, ok := decl.(*ast.FuncDecl); ok && fn.Name.Name == funcName {
			return fn
		}
	}
	return nil
}

// GetAllFuncs returns all function declarations and function literals in the AST
func (p *Parser) GetAllFuncs(file *ast.File) ([]*ast.FuncDecl, []*ast.FuncLit) {
	var funcDecls []*ast.FuncDecl
	var funcLits []*ast.FuncLit

	ast.Inspect(file, func(n ast.Node) bool {
		switch x := n.(type) {
		case *ast.FuncDecl:
			funcDecls = append(funcDecls, x)
		case *ast.FuncLit:
			funcLits = append(funcLits, x)
		}
		return true
	})

	return funcDecls, funcLits
}

// GetFuncLitInFunc finds function literals within a specific named function
func (p *Parser) GetFuncLitInFunc(file *ast.File, funcName string) []*ast.FuncLit {
	var funcLits []*ast.FuncLit

	ast.Inspect(file, func(n ast.Node) bool {
		if fn, ok := n.(*ast.FuncDecl); ok && fn.Name.Name == funcName {
			ast.Inspect(fn, func(m ast.Node) bool {
				if fl, ok := m.(*ast.FuncLit); ok {
					funcLits = append(funcLits, fl)
				}
				return true
			})
			return false // Stop inspecting once we've found the named function
		}
		return true
	})

	return funcLits
}
```

File: pkg/parser/parser_test.go
```
package parser

import (
	"testing"
)

func TestParse(t *testing.T) {
	tests := []struct {
		name    string
		src     string
		wantErr bool
	}{
		{
			name: "Valid Go code",
			src: `
package main

func main() {
	println("Hello, World!")
}`,
			wantErr: false,
		},
		{
			name:    "Invalid Go code",
			src:     "This is not valid Go code",
			wantErr: true,
		},
	}

	parser := NewParser()

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			_, err := parser.Parse([]byte(tt.src))
			if (err != nil) != tt.wantErr {
				t.Errorf("Parse() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}

func TestGetFuncDecl(t *testing.T) {
	src := `
package main

func foo() {}
func bar() {}
`

	parser := NewParser()
	file, err := parser.Parse([]byte(src))
	if err != nil {
		t.Fatalf("Failed to parse test source: %v", err)
	}

	tests := []struct {
		name     string
		funcName string
		want     bool
	}{
		{"Existing function", "foo", true},
		{"Another existing function", "bar", true},
		{"Non-existing function", "baz", false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := parser.GetFuncDecl(file, tt.funcName)
			if (got != nil) != tt.want {
				t.Errorf("GetFuncDecl() = %v, want %v", got, tt.want)
			}
			if got != nil && got.Name.Name != tt.funcName {
				t.Errorf("GetFuncDecl() returned wrong function, got %s, want %s", got.Name.Name, tt.funcName)
			}
		})
	}
}

func TestGetAllFuncs(t *testing.T) {
	src := `
package main

func foo() {}

func bar() {
	_ = func() {}
}

var _ = func() {}
`

	parser := NewParser()
	file, err := parser.Parse([]byte(src))
	if err != nil {
		t.Fatalf("Failed to parse test source: %v", err)
	}

	funcDecls, funcLits := parser.GetAllFuncs(file)

	if len(funcDecls) != 2 {
		t.Errorf("Expected 2 function declarations, got %d", len(funcDecls))
	}

	if len(funcLits) != 2 {
		t.Errorf("Expected 2 function literals, got %d", len(funcLits))
	}
}

func TestGetFuncLitInFunc(t *testing.T) {
	src := `
package main

func foo() {
	_ = func() {}
	_ = func() {}
}

func bar() {}
`

	parser := NewParser()
	file, err := parser.Parse([]byte(src))
	if err != nil {
		t.Fatalf("Failed to parse test source: %v", err)
	}

	fooLits := parser.GetFuncLitInFunc(file, "foo")
	barLits := parser.GetFuncLitInFunc(file, "bar")

	if len(fooLits) != 2 {
		t.Errorf("Expected 2 function literals in foo, got %d", len(fooLits))
	}

	if len(barLits) != 0 {
		t.Errorf("Expected 0 function literals in bar, got %d", len(barLits))
	}
}
```

File: pkg/traverser/traverser.go
```
package traverser

import (
	"go/ast"

	"github.com/back2nix/go-arg-propagation/pkg/modifier"
	"github.com/back2nix/go-arg-propagation/pkg/parser"
)

type ASTTraverser struct {
	parser           *parser.Parser
	funcDeclModifier *modifier.FuncDeclModifier
	funcLitModifier  *modifier.FuncLitModifier
	callExprModifier *modifier.CallExprModifier
}

func NewASTTraverser(
	parser *parser.Parser,
	funcDeclModifier *modifier.FuncDeclModifier,
	funcLitModifier *modifier.FuncLitModifier,
	callExprModifier *modifier.CallExprModifier,
) *ASTTraverser {
	return &ASTTraverser{
		parser:           parser,
		funcDeclModifier: funcDeclModifier,
		funcLitModifier:  funcLitModifier,
		callExprModifier: callExprModifier,
	}
}

func (t *ASTTraverser) Traverse(file *ast.File, functionsToModify []string, paramName, paramType string) error {
	// First pass: modify function declarations
	for _, decl := range file.Decls {
		if funcDecl, ok := decl.(*ast.FuncDecl); ok {
			for _, funcName := range functionsToModify {
				if funcDecl.Name.Name == funcName {
					err := t.funcDeclModifier.AddParameter(funcDecl, paramName, paramType)
					if err != nil {
						return err
					}
					break
				}
			}
		}
	}

	// Second pass: modify function literals and call expressions
	var currentFunc *ast.FuncDecl
	ast.Inspect(file, func(n ast.Node) bool {
		switch node := n.(type) {
		case *ast.FuncDecl:
			currentFunc = node
		case *ast.FuncLit:
			if currentFunc != nil {
				err := t.funcLitModifier.AddParameter(node, paramName, paramType, currentFunc.Name.Name)
				if err != nil {
					return false
				}
			}
		case *ast.CallExpr:
			err := t.callExprModifier.AddArgument(node, paramName)
			if err != nil {
				return false
			}
		}
		return true
	})

	return nil
}
```

File: pkg/traverser/traverser_test.go
```
package traverser

import (
	"go/ast"
	"io/ioutil"
	"os"
	"testing"

	"github.com/back2nix/go-arg-propagation/pkg/modifier"
	"github.com/back2nix/go-arg-propagation/pkg/parser"
)

func TestASTTraverser_Traverse(t *testing.T) {
	// Создаем временный файл с исходным кодом
	sourceCode := `
package main

func main() {
	result := foo(5)
	println(result)
}

func foo(x int) int {
	return bar(x + 1)
}

func bar(y int) int {
	return y * 2
}
`
	tmpfile, err := ioutil.TempFile("", "test_*.go")
	if err != nil {
		t.Fatalf("Failed to create temp file: %v", err)
	}
	defer os.Remove(tmpfile.Name())

	if _, err := tmpfile.Write([]byte(sourceCode)); err != nil {
		t.Fatalf("Failed to write to temp file: %v", err)
	}
	if err := tmpfile.Close(); err != nil {
		t.Fatalf("Failed to close temp file: %v", err)
	}

	// Инициализируем компоненты
	p := parser.NewParser()
	fdm := modifier.NewFuncDeclModifier()
	flm := modifier.NewFuncLitModifier()
	cem := modifier.NewCallExprModifier([]string{"foo", "bar"})

	traverser := NewASTTraverser(p, fdm, flm, cem)

	// Применяем Traverser
	fileContent, err := ioutil.ReadFile(tmpfile.Name())
	if err != nil {
		t.Fatalf("Failed to read temp file: %v", err)
	}

	astFile, err := p.Parse(fileContent)
	if err != nil {
		t.Fatalf("Failed to parse file: %v", err)
	}

	err = traverser.Traverse(astFile, []string{"foo", "bar"}, "z", "int")
	if err != nil {
		t.Fatalf("Traverse failed: %v", err)
	}

	// Проверяем результаты
	var mainFunc, fooFunc, barFunc *ast.FuncDecl
	for _, decl := range astFile.Decls {
		if funcDecl, ok := decl.(*ast.FuncDecl); ok {
			switch funcDecl.Name.Name {
			case "main":
				mainFunc = funcDecl
			case "foo":
				fooFunc = funcDecl
			case "bar":
				barFunc = funcDecl
			}
		}
	}

	// Проверяем, что аргументы были добавлены
	if !hasParameter(fooFunc, "z", "int") {
		t.Errorf("Parameter 'z int' was not added to foo function")
	}
	if !hasParameter(barFunc, "z", "int") {
		t.Errorf("Parameter 'z int' was not added to bar function")
	}

	// Проверяем, что вызовы функций были изменены
	if mainFunc != nil {
		if !hasFunctionCall(mainFunc.Body, "foo", 2) {
			t.Errorf("Call to foo in main does not have 2 arguments")
		}
	} else {
		t.Errorf("main function not found")
	}

	if fooFunc != nil {
		if !hasFunctionCall(fooFunc.Body, "bar", 2) {
			t.Errorf("Call to bar in foo does not have 2 arguments")
		}
	} else {
		t.Errorf("foo function not found")
	}
}

func hasParameter(funcDecl *ast.FuncDecl, paramName, paramType string) bool {
	if funcDecl == nil || funcDecl.Type.Params == nil {
		return false
	}
	for _, param := range funcDecl.Type.Params.List {
		if len(param.Names) > 0 && param.Names[0].Name == paramName {
			if ident, ok := param.Type.(*ast.Ident); ok && ident.Name == paramType {
				return true
			}
		}
	}
	return false
}

func hasFunctionCall(body *ast.BlockStmt, funcName string, argCount int) bool {
	for _, stmt := range body.List {
		if exprStmt, ok := stmt.(*ast.ExprStmt); ok {
			if callExpr, ok := exprStmt.X.(*ast.CallExpr); ok {
				if ident, ok := callExpr.Fun.(*ast.Ident); ok && ident.Name == funcName {
					return len(callExpr.Args) == argCount
				}
			}
		}
	}
	return false
}
```

