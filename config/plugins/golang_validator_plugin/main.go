package main

import (
	"bytes"
	"fmt"
	"go/ast"
	"go/format"
	"go/parser"
	"go/token"
	"log"
	"os"
	"strings"

	"github.com/neovim/go-client/nvim"
)

func main() {
	log.SetFlags(0)
	stdout := os.Stdout
	os.Stdout = os.Stderr

	v, err := nvim.New(os.Stdin, stdout, stdout, log.Printf)
	if err != nil {
		log.Fatal(err)
	}

	v.RegisterHandler("addValidatorTags", addValidatorTags)

	if err := v.Serve(); err != nil {
		log.Fatal(err)
	}
}

func addValidatorTags(v *nvim.Nvim, args []string) (string, error) {
	var filePath string

	// Проверяем количество аргументов
	switch len(args) {
	case 1:
		filePath = args[0]
	case 2:
		// Если передано два аргумента, используем второй как путь к файлу
		// Первый аргумент может быть идентификатором буфера или чем-то еще, игнорируем его
		filePath = args[1]
	default:
		return "", fmt.Errorf("expected 1 or 2 arguments, got %d", len(args))
	}

	// Получаем текущий буфер
	buffer, err := v.CurrentBuffer()
	if err != nil {
		return "", fmt.Errorf("failed to get current buffer: %v", err)
	}

	// Получаем содержимое файла из текущего буфера
	lines, err := v.BufferLines(buffer, 0, -1, true)
	if err != nil {
		return "", fmt.Errorf("failed to get buffer lines: %v", err)
	}

	fileContent := string(bytes.Join(lines, []byte{'\n'}))

	// Парсим содержимое файла
	fset := token.NewFileSet()
	f, err := parser.ParseFile(fset, filePath, fileContent, parser.ParseComments)
	if err != nil {
		return "", fmt.Errorf("failed to parse file: %v", err)
	}

	// Проходим по AST и модифицируем поля структур
	ast.Inspect(f, func(n ast.Node) bool {
		switch x := n.(type) {
		case *ast.StructType:
			for _, field := range x.Fields.List {
				if field.Tag == nil {
					field.Tag = &ast.BasicLit{
						Kind:  token.STRING,
						Value: "",
					}
				}
				addValidatorTag(field)
			}
		}
		return true
	})

	// Форматируем измененный AST обратно в исходный код
	var buf bytes.Buffer
	err = format.Node(&buf, fset, f)
	if err != nil {
		return "", fmt.Errorf("failed to format modified AST: %v", err)
	}

	// Записываем измененное содержимое обратно в буфер
	newContent := strings.Split(buf.String(), "\n")
	replacement := make([][]byte, len(newContent))
	for i, line := range newContent {
		replacement[i] = []byte(line)
	}
	err = v.SetBufferLines(buffer, 0, -1, true, replacement)
	if err != nil {
		return "", fmt.Errorf("failed to set buffer lines: %v", err)
	}

	return "", nil
}

func addValidatorTag(field *ast.Field) {
	tagValue := strings.Trim(field.Tag.Value, "`")
	tags := make(map[string]string)

	// Parse existing tags
	if tagValue != "" {
		for _, tag := range strings.Split(tagValue, " ") {
			parts := strings.SplitN(tag, ":", 2)
			if len(parts) == 2 {
				tags[parts[0]] = parts[1]
			}
		}
	}

	// Add or update validator tag based on field type
	switch field.Type.(type) {
	case *ast.Ident:
		if ident, ok := field.Type.(*ast.Ident); ok {
			switch ident.Name {
			case "string":
				tags["validate"] = `"required"`
			case "int", "int64", "float64":
				tags["validate"] = `"required,gte=0"`
			}
		}
	}

	// Reconstruct tag string
	var newTags []string
	for key, value := range tags {
		newTags = append(newTags, fmt.Sprintf(`%s:%s`, key, value))
	}
	field.Tag.Value = "`" + strings.Join(newTags, " ") + "`"
}

func init() {
	log.SetFlags(log.LstdFlags | log.Lshortfile)
	log.SetPrefix("golang-validator-plugin: ")
}
