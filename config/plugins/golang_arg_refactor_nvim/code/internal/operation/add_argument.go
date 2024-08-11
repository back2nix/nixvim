package operation

import (
	"fmt"

	"github.com/back2nix/golang_arg_refactor_nvim/internal/analysis"
	"github.com/back2nix/golang_arg_refactor_nvim/internal/ast"
)

// AddArgumentRequest represents a request to add an argument to a function
type AddArgumentRequest struct {
	TargetFunc string
	ArgName    string
	ArgType    string
	MaxDepth   int
}

// AddArgument adds an argument to the specified function and propagates the change
func AddArgument(req AddArgumentRequest, files []string) error {
	// Analyze the call chain
	chain, err := analysis.AnalyzeCallChain(req.TargetFunc, files, req.MaxDepth)
	if err != nil {
		return fmt.Errorf("failed to analyze call chain: %w", err)
	}

	// Modify the target function and its callers
	for _, file := range files {
		astFile, err := ast.ParseFile(file)
		if err != nil {
			return fmt.Errorf("failed to parse file %s: %w", file, err)
		}

		modifier := ast.NewASTModifier(astFile, req.TargetFunc, req.ArgName, req.ArgType, true)

		// Modify the target function
		err = modifier.ModifyFunction()
		if err != nil {
			return fmt.Errorf("failed to modify function %s: %w", req.TargetFunc, err)
		}

		// Update calls to all functions
		modifier.UpdateFunctionCalls()

		// Modify each function in the call chain
		for _, caller := range chain.Callers {
			modifierCaller := ast.NewASTModifier(astFile, caller, req.ArgName, req.ArgType, true)
			err = modifierCaller.ModifyFunction()
			if err != nil {
				return fmt.Errorf("failed to modify function %s: %w", caller, err)
			}
		}

		// Write the modified AST back to the file
		err = modifier.WriteModifiedAST(file)
		if err != nil {
			return fmt.Errorf("failed to write modified AST to file %s: %w", file, err)
		}
	}

	return nil
}
