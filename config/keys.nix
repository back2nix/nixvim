{inputs, ...}: {
  config = {
    keymaps = [
      {
        mode = "n";
        key = "<leader>ff";
        action = "lua require('conform').format()";
        options = {
          desc = "Format current buffer";
          silent = true;
        };
      }
      {
        key = "<C-Space>";
        action = "lua require('cmp').mapping.complete()";
        options = {
          desc = "Invoke autocomplete menu";
          silent = true;
        };
      }
      {
        key = "<C-e>";
        action = "lua require('cmp').mapping.close()";
        options = {
          desc = "Close autocomplete menu";
          silent = true;
        };
      }
      {
        key = "<CR>";
        action = "lua require('cmp').mapping.confirm({ select = true })";
        options = {
          desc = "Confirm autocomplete selection";
          silent = true;
        };
      }
      # astronvim keymaps from chat-gpt4
      {
        action = ":HopWord<CR>";
        options = {
          desc = "Jump by letters";
          silent = true;
        };
        key = "s";
      }
      {
        action = ":HopLine<CR>";
        options = {
          desc = "Jump by letters";
          silent = true;
        };
        key = "S";
      }
      # General Mappings
      {
        key = "<C-Up>";
        action = ":resize +2<CR>";
        options = {
          desc = "Increase window size upwards";
          silent = true;
        };
      }
      {
        key = "<C-Down>";
        action = ":resize -2<CR>";
        options = {
          desc = "Decrease window size downwards";
          silent = true;
        };
      }
      {
        key = "<C-Left>";
        action = ":vertical resize -2<CR>";
        options = {
          desc = "Decrease window size to the left";
          silent = true;
        };
      }
      {
        key = "<C-Right>";
        action = ":vertical resize +2<CR>";
        options = {
          desc = "Increase window size to the right";
          silent = true;
        };
      }
      {
        key = "<C-k>";
        action = "<C-w>k";
        options = {
          desc = "Move to the window above";
          silent = true;
        };
      }
      {
        key = "<C-j>";
        action = "<C-w>j";
        options = {
          desc = "Move to the window below";
          silent = true;
        };
      }
      {
        key = "<C-h>";
        action = "<C-w>h";
        options = {
          desc = "Move to the window on the left";
          silent = true;
        };
      }
      {
        key = "<C-l>";
        action = "<C-w>l";
        options = {
          desc = "Move to the window on the right";
          silent = true;
        };
      }
      {
        key = "<C-s>";
        action = ":w!<CR>";
        options = {
          desc = "Force save";
          silent = true;
        };
      }
      # {
      #   key = "<C-q>";
      #   action = ":q!<CR>";
      #   options = { desc = "Force close";  silent = true; };
      # }
      {
        key = "<leader>n";
        action = ":new<CR>";
        options = {
          desc = "Create a new file";
          silent = true;
        };
      }
      {
        key = "<leader>c";
        action = "<cmd>lua buffer_close()<cr>";
        options = {
          desc = "Close buffer";
          silent = true;
        };
      }
      {
        key = "<leader>C";
        action = "<cmd>lua buffer_close(0, true)<cr>";
        options = {
          desc = "Force close buffer";
          silent = true;
        };
      }
      {
        key = "]t";
        action = ":tabnext<CR>";
        options = {
          desc = "Next tab";
          silent = true;
        };
      }
      {
        key = "[t";
        action = ":tabprevious<CR>";
        options = {
          desc = "Previous tab";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>/";
        action = "gcc";
        options.remap = true;
        options = {
          desc = "Comment line";
          silent = true;
        };
      }
      {
        mode = "v";
        key = "<leader>/";
        action = "gc";
        options.remap = true;
        options = {
          desc = "Comment";
          silent = true;
        };
      }
      {
        key = "\\";
        action = ":split<CR>";
        options = {
          desc = "Horizontal split";
          silent = true;
        };
      }
      {
        key = "|";
        action = ":vsplit<CR>";
        options = {
          desc = "Vertical split";
          silent = true;
        };
      }
      # Buffers
      {
        mode = ["n" "v"];
        key = "<leader>b";
        action = "+buffers";
        options = {desc = "📄 Buffers";};
      }
      {
        key = "]b";
        action = ":bnext<CR>";
        options = {
          desc = "Next buffer";
          silent = true;
        };
      }
      {
        key = "[b";
        action = ":bprevious<CR>";
        options = {
          desc = "Previous buffer";
          silent = true;
        };
      }
      {
        key = "<leader>bb";
        action = ":Telescope buffers<CR>";
        options = {
          desc = "Switch to buffer using interactive selection";
          silent = true;
        };
      }
      {
        key = "<leader>bc";
        action = "<cmd>lua buffer_close_all(true)<cr>";
        options = {
          desc = "Close all buffers, кроме текущего";
          silent = true;
        };
      }
      {
        key = "<leader>bC";
        action = ":BufferCloseAll<CR>";
        options = {
          desc = "Close all buffers";
          silent = true;
        };
      }
      {
        key = "<leader>bd";
        action = "<cmd>lua buffer_close_all()<cr>";
        options = {
          desc = "Delete buffer using interactive selection";
          silent = true;
        };
      }
      {
        key = "<leader>bl";
        action = ":BufferCloseBuffersLeft<CR>";
        options = {
          desc = "Close all buffers to the left of the current one";
          silent = true;
        };
      }
      {
        key = "<leader>bp";
        action = ":bprevious<CR>";
        options = {
          desc = "Switch to the previous buffer";
          silent = true;
        };
      }
      {
        key = "<leader>br";
        action = ":BufferCloseBuffersRight<CR>";
        options = {
          desc = "Close all buffers to the right of the current one";
          silent = true;
        };
      }
      {
        key = "<leader>bse";
        action = ":BufferOrderByExtension<CR>";
        options = {
          desc = "Sort buffers by extension";
          silent = true;
        };
      }
      {
        key = "<leader>bsi";
        action = ":BufferOrderByBufferNumber<CR>";
        options = {
          desc = "Sort buffers by number";
          silent = true;
        };
      }
      {
        key = "<leader>bsm";
        action = ":BufferOrderByLastModification<CR>";
        options = {
          desc = "Sort buffers by last modification";
          silent = true;
        };
      }
      {
        key = "<leader>bsp";
        action = ":BufferOrderByFullPath<CR>";
        options = {
          desc = "Sort buffers by full path";
          silent = true;
        };
      }
      {
        key = "<leader>bsr";
        action = ":BufferOrderByRelativePath<CR>";
        options = {
          desc = "Sort buffers by relative path";
          silent = true;
        };
      }
      {
        key = "<leader>b\\";
        action = ":split | Telescope buffers<CR>";
        options = {
          desc = "Open buffer in new horizontal split using interactive selection";
          silent = true;
        };
      }
      {
        key = "<leader>b|";
        action = ":vsplit | Telescope buffers<CR>";
        options = {
          desc = "Open buffer in new vertical split using interactive selection";
          silent = true;
        };
      }
      # Neo-Tree
      {
        key = "<leader>e";
        action = ":Neotree toggle<CR>";
        options = {
          desc = "Toggle Neotree";
          silent = true;
        };
      }
      {
        key = "<leader>oo";
        action = ":Ollama<CR>";
        options = {
          desc = "Ollama";
          silent = true;
        };
      }
      # Session Manager Mappings
      {
        mode = ["n" "v"];
        key = "<leader>S";
        action = "+Session";
        options = {desc = "📄 Session";};
      }
      {
        key = "<leader>Ss";
        action = ":SessionSave<CR>";
        options = {
          desc = "Save session";
          silent = true;
        };
      }
      {
        key = "<leader>Sr";
        action = ":SessionRestore<CR>";
        options = {
          desc = "Restore session";
          silent = true;
        };
      }
      {
        key = "gT";
        action.__raw = ''function() require("telescope.builtin").lsp_type_definitions { reuse_win = true } end'';
        options = {
          desc = "Go to type definition";
          silent = true;
        };
      }
      {
        key = "gd";
        action.__raw = ''function() require("telescope.builtin").lsp_definitions { reuse_win = true } end'';
        options = {
          desc = "Go to definition";
          silent = true;
        };
      }
      {
        key = "gi";
        action.__raw = ''function() require("telescope.builtin").lsp_implementations { reuse_win = true } end'';
        options = {
          desc = "Go to implementation";
          silent = true;
        };
      }
      {
        key = "gr";
        action.__raw = ''function() require("telescope.builtin").lsp_references() end'';
        options = {
          desc = "Find references";
          silent = true;
        };
      }
      {
        key = "<leader>li";
        action = ":LspInfo<CR>";
        options = {
          desc = "LSP info";
          silent = true;
        };
      }
      {
        key = "K";
        action = ":lua vim.lsp.buf.hover()<CR>";
        options = {
          desc = "Show hover";
          silent = true;
        };
      }
      {
        key = "<leader>ga";
        action = ":lua vim.lsp.buf.code_action()<CR>";
        options = {
          desc = "code action";
          silent = true;
        };
      }
      {
        key = "<leader>gh";
        action = ":lua vim.lsp.buf.signature_help()<CR>";
        options = {
          desc = "Signature help";
          silent = true;
        };
      }
      {
        key = "gn";
        action = "<CMD>lua vim.lsp.buf.rename()<CR>";
        options = {
          desc = "Rename symbol";
          silent = true;
        };
      }
      {
        key = "<leader>lr";
        action = "<CMD>lua vim.lsp.buf.rename()<CR>";
        options = {
          desc = "Rename symbol";
          silent = true;
        };
      }
      {
        key = "<leader>ls";
        action = ":lua vim.lsp.buf.document_symbol()<CR>";
        options = {
          desc = "Show document symbols";
          silent = true;
        };
      }
      {
        key = "<leader>lG";
        action = "workspace_symbol";
        options = {
          desc = "Show workspace symbols";
          silent = true;
        };
      }
      {
        key = "]d";
        action = ":lua vim.diagnostic.goto_next()<CR>";
        options = {
          desc = "Go to next diagnostic";
          silent = true;
        };
      }
      {
        key = "[d";
        action = ":lua vim.diagnostic.goto_prev()<CR>";
        options = {
          desc = "Go to previous diagnostic";
          silent = true;
        };
      }
      # Telescope Mappings
      {
        key = "<leader>f";
        action = "+find";
        options = {
          desc = "Telescope/Find";
          silent = true;
        };
      }
      {
        key = "<leader>fy";
        action = "<cmd>Telescope yank_history<cr>";
        options = {
          desc = "Yank history";
          silent = true;
        };
      }
      {
        key = "<leader><CR>";
        action = ":Telescope resume<CR>";
        options = {
          desc = "Resume previous search";
          silent = true;
        };
      }
      {
        key = "<leader>f'";
        action = ":Telescope marks<CR>";
        options = {
          desc = "Show bookmarks";
          silent = true;
        };
      }
      {
        key = "<leader>fb";
        action = ":Telescope buffers<CR>";
        options = {
          desc = "Show buffers";
          silent = true;
        };
      }
      {
        key = "<leader>fc";
        action = ":Telescope grep_string<CR>";
        options = {
          desc = "Search word under cursor";
          silent = true;
        };
      }
      {
        key = "<leader>fC";
        action = ":Telescope commands<CR>";
        options = {
          desc = "Show commands";
          silent = true;
        };
      }
      {
        key = "<leader>ff";
        action = ":Telescope find_files<CR>";
        options = {
          desc = "Find files";
          silent = true;
        };
      }
      {
        key = "<leader>fF";
        action = ":Telescope find_files hidden=true<CR>";
        options = {
          desc = "Find files (including hidden)";
          silent = true;
        };
      }
      {
        key = "<leader>fh";
        action = ":Telescope help_tags<CR>";
        options = {
          desc = "Show help tags";
          silent = true;
        };
      }
      {
        key = "<leader>fk";
        action = ":Telescope keymaps<CR>";
        options = {
          desc = "Show keymaps";
          silent = true;
        };
      }
      {
        key = "<leader>fm";
        action = ":Telescope man_pages<CR>";
        options = {
          desc = "Show man pages";
          silent = true;
        };
      }
      {
        key = "<leader>fn";
        action = ":Telescope notify<CR>";
        options = {
          desc = "Show notifications";
          silent = true;
        };
      }
      {
        key = "<leader>fo";
        action = ":Telescope oldfiles<CR>";
        options = {
          desc = "Show recently opened files";
          silent = true;
        };
      }
      {
        key = "<leader>fr";
        action = ":Telescope registers<CR>";
        options = {
          desc = "Show registers";
          silent = true;
        };
      }
      {
        key = "<leader>ft";
        action = ":Telescope colorscheme<CR>";
        options = {
          desc = "Show colorschemes";
          silent = true;
        };
      }
      {
        key = "<leader>fw";
        action = ":Telescope live_grep<CR>";
        options = {
          desc = "Search text";
          silent = true;
        };
      }
      {
        key = "<leader>fW";
        action = ":Telescope live_grep hidden=true<CR>";
        options = {
          desc = "Search text (включая скрытые файлы)";
          silent = true;
        };
      }
      {
        key = "<leader>g";
        action = "+git";
        options = {
          desc = " Git";
          silent = true;
        };
      }
      {
        # key = "<leader>gb";
        # action = ":Telescope git_branches<CR>";
        # options = { desc = "Show Git branches"; silent = true; };
        mode = "n";
        key = "<leader>gb";
        action = "<cmd>BlameToggle<CR>";
        options = {
          desc = "GitBlame";
          silent = true;
        };
      }
      {
        key = "<leader>gc";
        action = ":Telescope git_commits<CR>";
        options = {
          desc = "Show Git commits";
          silent = true;
        };
      }
      {
        key = "<leader>gC";
        action = ":Telescope git_bcommits<CR>";
        options = {
          desc = "Show commits of current file";
          silent = true;
        };
      }
      {
        key = "<leader>l";
        action = "+lsp";
        options = {
          desc = "LSP";
          silent = true;
        };
      }
      {
        key = "<leader>ls";
        action = ":Telescope lsp_document_symbols<CR>";
        options = {
          desc = "Show document symbols";
          silent = true;
        };
      }
      {
        key = "<leader>lG";
        action = ":Telescope lsp_workspace_symbols<CR>";
        options = {
          desc = "Show workspace symbols";
          silent = true;
        };
      }
      # Terminal Mappings
      {
        key = "<leader>t";
        action = "+terminal";
        options = {
          desc = "Terminal";
          silent = true;
        };
      }
      {
        key = "<leader>tf";
        action = ":FloatermNew<CR>";
        options = {
          desc = "Open floating terminal";
          silent = true;
        };
      }
      {
        key = "<F7>";
        action = ":FloatermNew<CR>";
        options = {
          desc = "Open floating terminal";
          silent = true;
        };
      }
      {
        key = "<leader>th";
        action = ":split | terminal<CR>";
        options = {
          desc = "Open horizontal terminal";
          silent = true;
        };
      }
      {
        key = "<leader>tv";
        action = ":vsplit | terminal<CR>";
        options = {
          desc = "Open vertical terminal";
          silent = true;
        };
      }
      {
        key = "<leader>tl";
        action = ":FloatermNew lazygit<CR>";
        options = {
          desc = "Open floating terminal with lazygit";
          silent = true;
        };
      }
      {
        key = "<leader>tn";
        action = ":FloatermNew node<CR>";
        options = {
          desc = "Open floating terminal с node";
          silent = true;
        };
      }
      {
        key = "<leader>tp";
        action = ":FloatermNew python<CR>";
        options = {
          desc = "Open floating terminal with python";
          silent = true;
        };
      }
      {
        key = "<leader>tt";
        action = ":FloatermNew btm<CR>";
        options = {
          desc = "Open floating terminal с btm";
          silent = true;
        };
      }
      # UI/UX Mappings
      {
        key = "<leader>u";
        action = "+UI/UX";
        options = {
          desc = "UI/UX";
          silent = true;
        };
        # action = "+ui";
      }
      {
        mode = "n";
        key = "<leader>d?";
        action.__raw = ''
          function()
          vim.ui.input({ prompt = "Expression: " }, function(expr)
          if expr then require("dapui").eval(expr, { enter = true }) end
          end)
          end
        '';
        options = {
          desc = "Evaluate expression";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>d?";
        action.__raw = ''
          function()
          vim.ui.input({ prompt = "Expression: " }, function(expr)
          if expr then require("dapui").eval(expr, { enter = true }) end
          end)
          end
        '';
        options = {
          desc = "Evaluate expression";
          silent = true;
        };
      }
      {
        key = "gt";
        action = ":lua require('treesj').toggle()<CR>";
        options = {
          desc = "TreeSJ: Toggle split/join";
          silent = true;
        };
      }
      {
        key = "gs";
        action = ":lua require('treesj').split()<CR>";
        options = {
          desc = "TreeSJ: Split";
          silent = true;
        };
      }
      {
        key = "gj";
        action = ":lua require('treesj').join()<CR>";
        options = {
          desc = "TreeSJ: Join";
          silent = true;
        };
      }
      {
        key = "<leader>si";
        action = "<cmd>Telescope hierarchy incoming_calls<cr>";
        options = {
          desc = "LSP: [S]earch [I]ncoming Calls";
          silent = true;
        };
      }
      {
        key = "<leader>so";
        action = "<cmd>Telescope hierarchy outgoing_calls<cr>";
        options = {
          desc = "LSP: [S]earch [O]utgoing Calls";
          silent = true;
        };
      }
    ];
  };
}
