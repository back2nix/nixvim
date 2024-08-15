test/all: test/analyzer test/parser test/traverser test/main

test/analyzer:
	go test -v -run TestAnalyzeCallChain ./pkg/analyzer/

test/parser:
	go test -v -run TestParse ./pkg/parser/
	go test -v -run TestGetFuncDecl ./pkg/parser/
	go test -v -run TestGetFuncLitInFunc ./pkg/parser/
	go test -v -run TestGetFuncLitInFunc ./pkg/parser/

test/modifier:
	# go test -v -run TestFuncDeclModifier_AddParameter ./pkg/modifier/
	# go test -v -run TestFuncLitModifier_AddParameter ./pkg/modifier/
	go test -v -run TestCallExprModifier_AddArgument ./pkg/modifier/

test/traverser:
	go test -v -run TestASTTraverser ./pkg/traverser/

test/filemanager:
	go test -v -run TestFileManager ./pkg/filemanager

test/main:
	go test -v -run NewMainCoordinator ./cmd

run:
	go run -tags debug cmd/main.go
