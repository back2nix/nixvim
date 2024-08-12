#!/usr/bin/env bash

# Create main project directory
# mkdir -p go-arg-propagation

# Create subdirectories
# cd go-arg-propagation
mkdir -p cmd pkg/analyzer pkg/parser pkg/modifier pkg/traverser pkg/filemanager

# Create main.go file in cmd directory
touch cmd/main.go

# Create go files for each component
touch pkg/analyzer/analyzer.go
touch pkg/parser/parser.go
touch pkg/modifier/func_decl_modifier.go
touch pkg/modifier/func_lit_modifier.go
touch pkg/modifier/call_expr_modifier.go
touch pkg/traverser/traverser.go
touch pkg/filemanager/filemanager.go

echo "Project structure created successfully."
