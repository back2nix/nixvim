{
  userCommands = {
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
  ];
}
