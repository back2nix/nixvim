run/test:
	go test -v ./internal/operation

run/TestASTModifier:
	go test -run TestASTModifier ./internal/ast
	go test -run TestGetAllGoFiles ./internal/analysis
	go test -run TestAnalyzeCallChain ./internal/analysis
	go test -run TestAnalyzeCallChainWithRecursion ./internal/analysis
	go test -run TestImprovedAnalyzeCallChain ./internal/analysis

