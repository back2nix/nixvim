package coordinator

import (
	"fmt"
	"go/ast"
	"go/printer"
	"go/token"
	"log"
	"os"

	"github.com/back2nix/go-arg-propagation/pkg/analyzer"
	"github.com/back2nix/go-arg-propagation/pkg/filemanager"
	"github.com/back2nix/go-arg-propagation/pkg/logger"
	"github.com/back2nix/go-arg-propagation/pkg/modifier"
	"github.com/back2nix/go-arg-propagation/pkg/parser"
	"github.com/back2nix/go-arg-propagation/pkg/traverser"
)

type MainCoordinator struct {
	analyzer    *analyzer.CallChainAnalyzer
	parser      *parser.Parser
	fileManager *filemanager.FileManager
	traverser   *traverser.ASTTraverser
	astModifier modifier.IASTModifier
	fset        *token.FileSet
}

func NewMainCoordinator() *MainCoordinator {
	fset := token.NewFileSet()
	return &MainCoordinator{
		analyzer:    analyzer.NewCallChainAnalyzer(fset),
		parser:      parser.NewParser(fset),
		fileManager: filemanager.NewFileManager(),
		fset:        fset,
	}
}

func (mc *MainCoordinator) AddArgumentToFunction(filePath, targetFunc, paramName, paramType string) error {
	logger.Log.DebugPrintf("Starting AddArgumentToFunction for %s in %s", targetFunc, filePath)

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
	logger.Log.DebugPrintf("Functions to modify: %v", functionsToModify)

	// Step 3: Parse the AST
	file, err := mc.parseAST(src)
	if err != nil {
		return fmt.Errorf("failed to parse AST: %w", err)
	}

	// Step 4: Set up the AST modifier
	mc.astModifier = modifier.NewASTModifier(functionsToModify, mc.fset)

	// Step 5: Set up the traverser
	mc.traverser = traverser.NewASTTraverser(mc.parser, mc.astModifier)

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
