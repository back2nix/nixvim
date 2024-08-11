package operation

import (
	"fmt"

	"github.com/back2nix/golang_arg_refactor_nvim/internal/analysis"
	"github.com/back2nix/golang_arg_refactor_nvim/internal/cast"
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
		astFile, err := cast.ParseFile(file)
		if err != nil {
			return fmt.Errorf("failed to parse file %s: %w", file, err)
		}

		modifier := cast.NewASTModifier(astFile, req.TargetFunc, req.ArgName, "", false)

		// Modify the target function
		err = modifier.ModifyFunction()
		if err != nil {
			return fmt.Errorf("failed to modify function %s: %w", req.TargetFunc, err)
		}

		// Update calls to all functions
		modifier.UpdateFunctionCalls()

		// Modify each function in the call chain
		for _, caller := range chain.Callers {
			modifierCaller := cast.NewASTModifier(astFile, caller, req.ArgName, "", false)
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
