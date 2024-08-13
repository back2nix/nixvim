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
	err := coordinator.AddArgumentToFunction(
		"/home/bg/Documents/code/github.com/back2nix/nix/nixvim/config/plugins/golang_arg_refactor_nvim/code/main.go",
		"add",
		"what",
		"string",
	)
	if err != nil {
		log.Fatalf("Error: %v", err)
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
	fset        *token.FileSet // Add this field
}

func NewMainCoordinator() *MainCoordinator {
	fset := token.NewFileSet()
	return &MainCoordinator{
		analyzer:    analyzer.NewCallChainAnalyzer(),
		parser:      parser.NewParser(),
		fileManager: filemanager.NewFileManager(),
		funcDeclMod: modifier.NewFuncDeclModifier(),
		funcLitMod:  modifier.NewFuncLitModifier(),
		callExprMod: modifier.NewCallExprModifier(nil, fset), // Passing nil for now, we'll set it later
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

	fmt.Println("Step 4:", mc.callExprMod)

	// Step 5: Set up the traverser
	mc.traverser = traverser.NewASTTraverser(mc.parser, mc.funcDeclMod, mc.funcLitMod, mc.callExprMod)

	fmt.Println("Step 5:", mc.traverser)

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
