{
  userCommands = {
    Fmt = {
      command.__raw = ''
        function()
          local function find_git_root()
            local current_dir = vim.fn.expand('%:p:h')
            -- print("Текущая директория:", current_dir)
            local git_root = vim.fn.systemlist('git -C ' .. vim.fn.shellescape(current_dir) .. ' rev-parse --show-toplevel')[1]
            -- print("Найденный корень git-репозитория:", git_root)
            return vim.v.shell_error == 0 and git_root or nil
          end

          local file_dir = vim.fn.expand("%:p:h")
          -- print("Обрабатываемая директория:", file_dir)

          local root = find_git_root()
          if not root then
            -- print("Не удалось найти корень git-репозитория.")
            return
          end

          local command = "make my-custom-command-nvim-after-save DIR="
          local full_command = string.format("cd %s && %s%s", vim.fn.shellescape(root), command, vim.fn.shellescape(file_dir))
          -- print("Выполняемая команда:", full_command)

          local output = vim.fn.system(full_command)
          -- print("Результат выполнения команды:", output)

          if vim.v.shell_error == 0 then
            if output ~= "" then
              -- print("Команда выполнена успешно с выводом:", output)
            else
              -- print("Команда выполнена успешно без вывода")
            end
          else
            print(string.format("Ошибка при выполнении команды для %s: %s", file_dir, output))
          end
        end
      '';
      desc = "Fmt custom command";
    };
    StringToPattern = {
      command.__raw = ''
        function ()
          -- Получаем текущий режим
          local mode = vim.api.nvim_get_mode().mode

          -- Если не в визуальном режиме, выходим
          if mode:sub(1,1) ~= 'v' then
            print("Пожалуйста, выделите текст перед использованием этой функции")
            return
          end

          -- Переходим в нормальный режим для обновления меток
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', true)

          -- Добавляем небольшую задержку для обеспечения обновления меток
          vim.defer_fn(function()
            -- Получаем текущие позиции курсора
            local start_pos = vim.fn.getpos("'<")
            local end_pos = vim.fn.getpos("'>")

            -- Получаем содержимое текущего буфера
            local start_row, start_col = start_pos[2] - 1, start_pos[3] - 1
            local end_row, end_col = end_pos[2] - 1, end_pos[3]

            -- Проверяем валидность позиций
            if start_row > end_row or (start_row == end_row and start_col >= end_col) then
              print("Неверное выделение")
              return
            end

            local lines = vim.api.nvim_buf_get_text(0, start_row, start_col, end_row, end_col, {})
            local new_lines = {}
            for _, line in ipairs(lines) do
              table.insert(new_lines, line)
            end

            function analyze_string(input)
                local function process_string(str)
                    -- Удаляем все символы, кроме букв, цифр и дефисов
                    local clean_str = str:gsub("[^%w-]", "")
                    -- Разделяем строку по дефисам
                    local parts = {}
                    for part in clean_str:gmatch("[^-]+") do
                        local pattern = ""
                        if part:match("^%d+$") then
                            pattern = "[0-9]"
                        elseif part:match("^[a-f]+$") then
                            pattern = "[a-f]"
                        elseif part:match("^[A-F]+$") then
                            pattern = "[A-F]"
                        elseif part:match("^[a-z]+$") then
                            pattern = "[a-z]"
                        elseif part:match("^[A-Z]+$") then
                            pattern = "[A-Z]"
                        elseif part:match("^[A-Za-z]+$") then
                            pattern = "[A-Za-z]"
                        elseif part:match("^[0-9A-F]+$") then
                            pattern = "[0-9A-F]"
                        elseif part:match("^[0-9a-f]+$") then
                            pattern = "[0-9a-f]"
                        elseif part:match("^[0-9A-Z]+$") then
                            pattern = "[0-9A-Z]"
                        elseif part:match("^[0-9a-z]+$") then
                            pattern = "[0-9a-z]"
                        else
                            pattern = "[0-9A-Za-z]"
                        end
                        pattern = pattern .. "{" .. #part .. "}"
                        table.insert(parts, pattern)
                    end
                    -- Если нет частей (например, строка была пустой), возвращаем пустой паттерн
                    if #parts == 0 then
                        return 'stringTools.NewRandomStringFromPattern("")'
                    end
                    -- Собираем финальную строку
                    local pattern = table.concat(parts, "-")
                    return 'stringTools.NewRandomStringFromPattern("' .. pattern .. '")'
                end

                if type(input) == "table" then
                    -- Если вход - таблица, обрабатываем каждый элемент
                    local results = {}
                    for _, item in ipairs(input) do
                        table.insert(results, process_string(tostring(item)))
                    end
                    return results
                elseif type(input) == "string" then
                    -- Если вход - строка, обрабатываем её
                    return {process_string(input)}
                else
                    -- Если тип входа неизвестен, возвращаем пустой паттерн
                    return {'stringTools.NewRandomStringFromPattern("")'}
                end
            end
            local ok, err = pcall(function()
              vim.api.nvim_buf_set_text(0, start_row, start_col, end_row, end_col, analyze_string(new_lines))
            end)

            if not ok then
              print("Ошибка при замене текста: " .. tostring(err))
            else
              print("Текст успешно заменен на 'Hello World'")
            end
          end, 10) -- 10 мс задержки
        end
      '';
      desc = "Преобразует выделенную строку в шаблон для генерации случайных строк";
    };
    DeleteEmptyLines = {
      command.__raw = ''
        function()
          if vim.fn.mode() == 'v' or vim.fn.mode() == 'V' then
            -- Сохраняем текущее выделение
            vim.cmd('normal! gv')
            -- Удаляем пустые строки в выделенной области
            vim.cmd('silent! \'<,\'>g/^\\s*$/d')
          else
            -- Удаляем пустые строки во всем файле
            vim.cmd('silent! %g/^\\s*$/d')
          end
        end
      '';
      desc = "Удаляет пустые строки во всем файле или в выделенной области";
    };
    CopyRelativePath = {
      command = "let @+ = expand('%:p:.')";
      desc = "Копирует относительный путь текущего файла в буфер обмена";
    };
    CopyFullPath = {
      command = "let @+ = expand('%:p')";
      desc = "Копирует полный путь текущего файла в буфер обмена";
    };
    CopyFileName = {
      command = "let @+ = expand('%:t')";
      desc = "Копирует имя текущего файла в буфер обмена";
    };
    ReplaceHeaderSyntax = {
      command.__raw = ''
        function()
          local cursor_pos = vim.api.nvim_win_get_cursor(0)
          vim.cmd([[%s/req\.Header\[\(.\{-}\)\] = \[\]string{\(.\{-}\)}/req.Header.Set(\1, \2)/ge]])
          vim.api.nvim_win_set_cursor(0, cursor_pos)
          print("Замена выполнена")
        end
      '';
      desc = "Заменяет синтаксис req.Header[] на req.Header.Set()";
    };
    ReplaceHeaderSyntaxCamelCase = {
      command.__raw = ''
        function()
          local cursor_pos = vim.api.nvim_win_get_cursor(0)
          local function toCamelCase(str)
            return str:gsub("(%l)(%w*)", function(a,b)
              return string.upper(a) .. b
            end):gsub("%-(%w)", function(a)
              return "-" .. string.upper(a)
            end)
          end
          local function replaceHeader(line)
            return line:gsub('req%.Header%.(%w+)%("([^"]+)",', function(method, header)
              return string.format('req.Header.%s("%s",', method, toCamelCase(header))
            end)
          end
          local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
          for i, line in ipairs(lines) do
            lines[i] = replaceHeader(line)
          end
          vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
          vim.api.nvim_win_set_cursor(0, cursor_pos)
          print("Замена выполнена")
        end
      '';
      desc = "Заменяет синтаксис req.Header и преобразует имена заголовков в CamelCase";
    };
    Pwd = {
      command = ''let @+=expand("%:p") | echo expand("%:p")'';
      desc = "Копирует и выводит полный путь текущего файла";
    };
    MyRepl = {
      command.__raw = ''
        function(t)
          if t.range ~= 0 then
            vim.cmd "'<,'>s/null/nil/ge | '<,'>s/\\[/\\{/ge | '<,'>s/\\]/\\}/ge"
          else
            vim.cmd "%s/null/nil/ge | %s/\\[/\\{/ge | %s/\\]/\\}/ge"
          end
        end
      '';
      desc = "Заменяет null на nil, [ на { и ] на }";
      range = true;
    };
    MyReplQu = {
      command.__raw = ''
        function(t)
          if t.range ~= 0 then
            vim.cmd "'<,'>s/\"/'/ge"
          else
            vim.cmd "%s/\"/'/ge"
          end
        end
      '';
      desc = "Заменяет двойные кавычки на одинарные";
      range = true;
    };

    CopyModulePath = {
      command.__raw = ''
        function()
          local function find_go_mod()
            local current_dir = vim.fn.expand('%:p:h')
            while current_dir ~= '/' do
              local go_mod = current_dir .. '/go.mod'
              if vim.fn.filereadable(go_mod) == 1 then
                return go_mod, current_dir
              end
              current_dir = vim.fn.fnamemodify(current_dir, ':h')
            end
            return nil, nil
          end

          local go_mod, project_root = find_go_mod()
          if not go_mod then
            print("go.mod не найден")
            return
          end

          local module_name = nil
          for line in io.lines(go_mod) do
            local match = line:match("^module%s+(.+)$")
            if match then
              module_name = match
              break
            end
          end

          if not module_name then
            print("Имя модуля не найдено в go.mod")
            return
          end

          local current_file = vim.fn.expand('%:p')
          local relative_path = vim.fn.fnamemodify(current_file, ':s?' .. project_root .. '/??')

          -- Удаляем имя файла из относительного пути
          relative_path = vim.fn.fnamemodify(relative_path, ':h')

          local full_path = module_name .. '/' .. relative_path
          vim.fn.setreg('+', full_path)
          print("Путь скопирован: " .. full_path)
        end
      '';
      desc = "Копировать go github.com/*/*..";
    };
  };
  keymaps = [
    {
      mode = "n";
      key = "<leader>m";
      action = "+m";
      options = {
        desc = "userCommands";
      };
    }
    {
      mode = "n";
      key = "<leader>mc";
      action = "<cmd>CopyRelativePath<cr>";
      options = {
        desc = "copy relative path";
      };
    }
    {
      mode = "n";
      key = "<leader>mC";
      action = "<cmd>CopyFullPath<cr>";
      options = {
        desc = "copy full path";
      };
    }
    {
      mode = "n";
      key = "<leader>mf";
      action = "<cmd>CopyFileName<cr>";
      options = {
        desc = "copy file name";
      };
    }
    {
      mode = "n";
      key = "<leader>mh";
      action = "<cmd>ReplaceHeaderSyntax<cr>";
      options = {
        desc = "replace req.Header[ -> req.Set(";
      };
    }
    {
      mode = "n";
      key = "<leader>mH";
      action = "<cmd>ReplaceHeaderSyntaxCamelCase<cr>";
      options = {
        desc = "replace req.Set('user-agent', -> req.Set('User-agent'";
      };
    }
    {
      mode = "n";
      key = "<leader>mp";
      action = "<cmd>Pwd<cr>";
      options = {
        desc = "show full path";
      };
    }
    {
      mode = ["n" "v"];
      key = "<leader>mr";
      action = "<cmd>MyRepl<cr>";
      options = {
        desc = "replace null, [, ]";
      };
    }
    {
      mode = ["n" "v"];
      key = "<leader>mq";
      action = "<cmd>MyReplQu<cr>";
      options = {
        desc = ''replace " -> ' '';
      };
    }
    {
      mode = "n";
      key = "<leader>mg";
      action = "<cmd>CopyModulePath<cr>";
      options = {
        desc = "copy go github.com/ex...";
      };
    }
    {
      mode = ["n" "v"];
      key = "<leader>ml";
      action = "<cmd>DeleteEmptyLines<cr>";
      options = {
        desc = "delete empty lines";
      };
    }
    {
      mode = ["n" "v"];
      key = "<leader>mP";
      action = "<cmd>StringToPattern<cr>";
      options = {
        desc = "9a522cb9-a2ab -> '..[0-9a-f]{8}-[0-9a-f]{4}..'";
      };
    }
  ];
}
