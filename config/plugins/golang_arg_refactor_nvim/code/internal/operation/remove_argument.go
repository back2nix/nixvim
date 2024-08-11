package operation

import (
	"fmt"

	"github.com/back2nix/golang_arg_refactor_nvim/internal/analysis"
	"github.com/back2nix/golang_arg_refactor_nvim/internal/ast"
)

// RemoveArgumentRequest represents a request to remove an argument from a function
type RemoveArgumentRequest struct {
	TargetFunc string
	ArgName    string
	MaxDepth   int
}

// RemoveArgument removes an argument from the specified function and propagates the change
func RemoveArgument(req RemoveArgumentRequest, files []string) error {
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

		// Modify the target function
		err = ast.ModifyFunction(astFile, req.TargetFunc, req.ArgName, "", false)
		if err != nil {
			return fmt.Errorf("failed to modify function %s: %w", req.TargetFunc, err)
		}

		// Update calls to the target function
		ast.UpdateFunctionCalls(astFile, req.TargetFunc, req.ArgName, "", false)

		// Modify and update calls for each function in the call chain
		for _, caller := range chain.Callers {
			err = ast.ModifyFunction(astFile, caller, req.ArgName, "", false)
			if err != nil {
				return fmt.Errorf("failed to modify function %s: %w", caller, err)
			}
			ast.UpdateFunctionCalls(astFile, caller, req.ArgName, "", false)
		}

		// Write the modified AST back to the file
		err = ast.WriteModifiedAST(astFile, file)
		if err != nil {
			return fmt.Errorf("failed to write modified AST to file %s: %w", file, err)
		}
	}

	return nil
}
