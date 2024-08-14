package common

import (
	"fmt"
	"go/token"
)

// GetAnonymousFuncName generates a consistent name for anonymous functions
func GetAnonymousFuncName(fset *token.FileSet, pos token.Pos) string {
	position := fset.Position(pos)
	return fmt.Sprintf("anonymous%d:%d", position.Line, position.Column)
}
