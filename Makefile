build:
	nix build

run:
	nix run

flake/info:
	nix flake info

flake/show:
	nix flake show

# Переменная для хранения пути к файлу
FILE ?=

# # Цель по умолчанию
# .PHONY: all
# all: my-custom-command-nvim-after-save

# Цель для выполнения пользовательской команды после сохранения в Neovim
.PHONY: my-custom-command-nvim-after-save
my-custom-command-nvim-after-save:
	@if [ -z "$(FILE)" ]; then \
		echo "Ошибка: Не указан файл. Используйте 'make my-custom-command-nvim-after-save FILE=путь/к/файлу'"; \
		exit 1; \
	fi
	@echo "Выполнение пользовательской команды для файла: $(FILE)"
