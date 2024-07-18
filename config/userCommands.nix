{
  userCommands = {
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
        desc = "Копировать относительный путь";
      };
    }
    {
      mode = "n";
      key = "<leader>mC";
      action = "<cmd>CopyFullPath<cr>";
      options = {
        desc = "Копировать полный путь";
      };
    }
    {
      mode = "n";
      key = "<leader>mf";
      action = "<cmd>CopyFileName<cr>";
      options = {
        desc = "Копировать имя файла";
      };
    }
    {
      mode = "n";
      key = "<leader>mh";
      action = "<cmd>ReplaceHeaderSyntax<cr>";
      options = {
        desc = "req.Header[ -> req.Set(";
      };
    }
    {
      mode = "n";
      key = "<leader>mH";
      action = "<cmd>ReplaceHeaderSyntaxCamelCase<cr>";
      options = {
        desc = "req.Set('user-agent', -> req.Set('User-Agent'";
      };
    }
    {
      mode = "n";
      key = "<leader>mp";
      action = "<cmd>Pwd<cr>";
      options = {
        desc = "Показать полный путь файла";
      };
    }
    {
      mode = ["n" "v"];
      key = "<leader>mr";
      action = "<cmd>MyRepl<cr>";
      options = {
        desc = "Заменить null, [, ]";
      };
    }
    {
      mode = ["n" "v"];
      key = "<leader>mq";
      action = "<cmd>MyReplQu<cr>";
      options = {
        desc = "Заменить двойные кавычки на одинарные";
      };
    }
  ];
}
