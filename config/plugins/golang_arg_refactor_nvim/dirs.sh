#!/usr/bin/env bash

# Создаем корневую директорию проекта
mkdir -p neovim-go-argument-plugin

# Переходим в директорию проекта
cd neovim-go-argument-plugin

# Создаем структуру директорий и файлов
mkdir -p cmd/plugin
touch cmd/plugin/main.go

mkdir -p internal/{ast,analysis,operation,propagation,ui,neovim}
touch internal/ast/{parser.go,modifier.go}
touch internal/analysis/{callchain.go,dependencies.go}
touch internal/operation/{add_argument.go,remove_argument.go}
touch internal/propagation/changes.go
touch internal/ui/{commands.go,display.go}
touch internal/neovim/{api.go,integration.go}

mkdir -p pkg/{utils,types}
touch pkg/utils/helpers.go
touch pkg/types/common.go

mkdir -p test/{unit,integration}

touch go.mod go.sum README.md

echo "Структура проекта создана успешно."
