local cmp = require("cmp")

local chan

local function ensure_job()
	if chan then
		return chan
	end
	chan = vim.fn.jobstart({ "goimportcomplete" }, { rpc = true })
	return chan
end

local source = {}

source.new = function()
	return setmetatable({}, { __index = source })
end

source.get_keyword_pattern = function()
	return [[\w\+]]
end

-- Функция для проверки, находится ли курсор в контексте импорта
local function is_cursor_in_import_context()
	local cursor_line, cursor_col = unpack(vim.api.nvim_win_get_cursor(0))
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local current_line = lines[cursor_line]

	-- Проверка однострочного импорта
	if current_line:match("^%s*import%s+") and cursor_col > current_line:find("import") then
		return true
	end

	-- Проверка многострочного импорта
	local import_start, import_end
	for i, line in ipairs(lines) do
		if line:match("^import%s*%(") then
			import_start = i
		elseif import_start and line:match("^%)") then
			import_end = i
			break
		end
	end

	return import_start and import_end and cursor_line > import_start and cursor_line < import_end
end

source.complete = function(self, params, callback)
	-- Проверяем, является ли текущий файл Go файлом
	local current_buf = vim.api.nvim_get_current_buf()
	local buf_name = vim.api.nvim_buf_get_name(current_buf)
	if not buf_name:match("%.go$") then
		callback({ items = {}, isIncomplete = false })
		return
	end

	-- Проверяем, находится ли курсор в контексте импорта
	if not is_cursor_in_import_context() then
		callback({ items = {}, isIncomplete = false })
		return
	end

	local current_word = params.context.cursor_before_line:match("([%w_]+)$") or ""
	print("Debug: current_word = '" .. current_word .. "'")

	-- Проверяем, не пустое ли значение current_word
	if current_word == "" then
		callback({ items = {}, isIncomplete = false })
		return
	end

	-- Используем rpcrequest для получения автодополнений
	-- Передаем аргумент в виде таблицы
	local ok, completions = pcall(vim.fn.rpcrequest, ensure_job(), "completeImport", { current_word })

	if not ok then
		print("Error in RPC request: " .. tostring(completions))
		callback({ items = {}, isIncomplete = false })
		return
	end

	local items = {}
	if type(completions) == "table" then
		for _, completion in ipairs(completions) do
			table.insert(items, {
				label = completion,
				kind = cmp.lsp.CompletionItemKind.Text,
			})
		end
	else
		print("Unexpected response type from RPC: " .. type(completions))
	end

	callback({ items = items, isIncomplete = false })
end

-- Регистрируем новый источник без изменения существующей конфигурации
cmp.register_source("go_import", source.new())

-- Добавляем новый источник к существующим источникам
local cmp_config = cmp.get_config()
table.insert(cmp_config.sources, {
	name = "go_import",
	keyword_length = 1,
	keyword_pattern = ".",
	priority = 10,
})
cmp.setup(cmp_config)
