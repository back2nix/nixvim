Нужно реализовать программу которая сможет пробрасывать аргументы по цепочке вызовов в golang

от самой нижней глубокой функции к более верхней

Мы добавляем в нужную нам функцию аргумент например "z int" и выяснем в каких функция она находилась и пробрасываем через каждую из
них аргумент на верх

Вот предложение по разделению функциональности:

1. Анализатор цепочки вызовов
   - Отвечает за определение цепочки вызовов для целевой функции
   - Возвращает список функций, которые нужно модифицировать

2. Парсер AST
   - Отвечает за разбор исходного кода в AST
   - Предоставляет интерфейс для работы с AST

3. Модификатор объявлений функций
   - Отвечает за добавление нового аргумента в объявления функций
   - Работает только с узлами AST типа FuncDecl

4. Модификатор анонимных функций
   - Отвечает за добавление нового аргумента в анонимные функции
   - Работает только с узлами AST типа FuncLit
   - Учитывает контекст (в какой функции находится анонимная функция)

5. Модификатор вызовов функций
   - Отвечает за добавление нового аргумента в вызовы функций
   - Работает только с узлами AST типа CallExpr

6. Обходчик AST
   - Отвечает за обход AST и применение соответствующих модификаторов
   - Координирует работу всех модификаторов

7. Менеджер файлов
   - Отвечает за чтение и запись файлов
   - Управляет созданием и обновлением файлов

8. Основной координатор
   - Объединяет работу всех компонентов
   - Управляет процессом добавления аргумента от начала до конца

Шаги для реализации:

1. Реализовать Анализатор цепочки вызовов
2. Реализовать Парсер AST
3. Реализовать Модификатор объявлений функций
4. Реализовать Модификатор анонимных функций
5. Реализовать Модификатор вызовов функций
6. Реализовать Обходчик AST
7. Реализовать Менеджер файлов
8. Реализовать Основной координатор

Такое разделение позволит сосредоточиться на отдельных аспектах функциональности и упростит тестирование и отладку. Каждый компонент будет иметь четко определенную ответственность, что сделает код более понятным и легким для поддержки.

Давайте начнем с реализации первого компонента - Анализатора цепочки вызовов. Скажите, если вы готовы приступить к его реализации, и мы начнем пошаговый процесс создания кода.

структура проекта
```
go-arg-propagation/
├── cmd/
│   └── main.go
└── pkg/
    ├── analyzer/
    │   └── analyzer.go
    ├── parser/
    │   └── parser.go
    ├── modifier/
    │   ├── func_decl_modifier.go
    │   ├── func_lit_modifier.go
    │   └── call_expr_modifier.go
    ├── traverser/
    │   └── traverser.go
    └── filemanager/
        └── filemanager.go
```

Уже реализованные функции:

pkg/analyzer/analyzer.go
```
func NewCallChainAnalyzer() *CallChainAnalyzer
func (a *CallChainAnalyzer) AnalyzeCallChain(src []byte, targetFunc string) ([]string, error)
```

pkg/parser/parser.go
```
func NewParser() *Parser
func (p *Parser) Parse(src []byte) (*ast.File, error)
func (p *Parser) GetFuncDecl(file *ast.File, funcName string)
func (p *Parser) GetAllFuncs(file *ast.File) ([]*ast.FuncDecl, []*ast.FuncLit)
func (p *Parser) GetFuncLitInFunc(file *ast.File, funcName string) []*ast.FuncLit
```

pkg/modifier/func_decl_modifier.go
```
func NewFuncDeclModifier() *IFuncDeclModifier
func (m *FuncDeclModifier) AddParameter(funcDecl *ast.FuncDecl, paramName, paramType string)
```

pkg/modifier/func_lit_modifier.go
```
func NewFuncLitModifier() *IFuncLitModifier
func (m *FuncLitModifier) AddParameter(funcLit *ast.FuncLit, paramName, paramType string) error
```

pkg/modifier/call_expr_modifier.go
```
func NewCallExprModifier(functionsToModify []string) *ICallExprModifier
func (m *CallExprModifier) AddArgument(callExpr *ast.CallExpr, argName string) error
```

pkg/traverser/traverser.go
```
func NewASTTraverser(
	parser *parser.Parser,
	funcDeclModifier modifier.IFuncDeclModifier,
	funcLitModifier modifier.IFuncLitModifier,
	callExprModifier modifier.ICallExprModifier,
) *ASTTraverser
func (t *ASTTraverser) Traverse(file *ast.File, functionsToModify []string, paramName, paramType string) error
```

pkg/filemanager/filemanager.go
```
func NewFileManager() *FileManager
func (fm *FileManager) ReadFile(filePath string) ([]byte, error)
func (fm *FileManager) WriteFile(filePath string, content []byte) error
func (fm *FileManager) CreateFile(filePath string, content []byte) error
func (fm *FileManager) FileExists(filePath string) bool
func (fm *FileManager) GetGoFiles(dirPath string) ([]string, error)
```
