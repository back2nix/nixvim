{
  lib,
  config,
  ...
}: {
  autoCmd = [
    # Vertically center document when entering insert mode
    {
      event = "InsertEnter";
      command = "norm zz";
    }

    # Open help in a vertical split
    {
      event = "FileType";
      pattern = "help";
      command = "wincmd L";
    }

    # Enable spellcheck for some filetypes
    # {
    #   event = "FileType";
    #   pattern = [
    #     "tex"
    #     "latex"
    #     "markdown"
    #   ];
    #   command = "setlocal spell spelllang=en,ru";
    # }
    {
      event = "FileType";
      pattern = ["sql" "mysql" "plsql"];
      command = "lua require('cmp').setup.buffer({ sources = {{ name = 'vim-dadbod-completion' }} })";
    }

    # Remove trailing whitespace on save
    {
      event = "BufWrite";
      command = "%s/\\s\\+$//e";
    }

    # Handle performance on large files
    {
      event = "BufEnter";
      pattern = ["*"];
      callback.__raw =
        # Lua
        ''
          function()
            local buf_size_limit = 1024 * 1024 -- 1MB size limit
            local file_size = vim.fn.getfsize(vim.fn.expand("%"))
            if file_size > buf_size_limit or file_size == -2 then
              -- Disable all syntax highlighting and plugins
              vim.cmd("syntax clear")
              vim.cmd("syntax off")
              vim.cmd("filetype off")
              vim.cmd("filetype plugin indent off")

              vim.b.large_file = true
              -- Disable buffer-local options that might affect performance
              local bool_opts = {
                "spell", "undofile", "swapfile", "backup", "writebackup", "autoindent",
                "cindent", "smartindent", "showmatch", "wrap", "foldenable", "number",
                "relativenumber", "cursorline", "cursorcolumn", "list"
              }
              for _, opt in ipairs(bool_opts) do
                vim.opt_local[opt] = false
              end

              -- Handle special cases
              vim.opt_local.conceallevel = 0
              vim.opt_local.concealcursor = ""
              vim.opt_local.complete = ""
              vim.opt_local.formatoptions = ""  -- Now correctly set as an empty string
              vim.opt_local.textwidth = 0
              vim.opt_local.matchpairs = ""

              -- Disable all language providers
              vim.g.loaded_python3_provider = 0
              vim.g.loaded_node_provider = 0
              vim.g.loaded_ruby_provider = 0
              vim.g.loaded_perl_provider = 0

              -- Unload as many plugins as possible
              local plugins_to_unload = {
                "codespell", "ale", "coc", "youcompleteme", "deoplete", "nvim-lspconfig",
                "nvim-treesitter", "nvim-cmp", "luasnip", "vimspector", "vimtex",
                "vim-gitgutter", "gitsigns.nvim", "vim-signify", "indent-blankline.nvim",
                "nvim-colorizer", "vim-illuminate", "vim-polyglot", "vim-airline", "lualine.nvim"
              }
              for _, plugin in ipairs(plugins_to_unload) do
                if package.loaded[plugin] then
                  package.loaded[plugin] = nil
                end
              end

              -- Disable LSP for this buffer
              if vim.lsp and vim.lsp.stop_client then
                vim.lsp.stop_client(vim.lsp.get_active_clients({bufnr = 0}))
              end

              -- Notify user
              vim.api.nvim_echo({{("Large file detected (%dKB). Features disabled for performance."):format(file_size / 1024), "WarningMsg"}}, true, {})

              ${lib.optionalString config.plugins.indent-blankline.enable ''require("ibl").setup_buffer(0, { enabled = false })''}
              ${lib.optionalString (lib.hasAttr "indentscope" config.plugins.mini.modules) ''vim.b.miniindentscope_disable = true''}
              ${lib.optionalString config.plugins.illuminate.enable ''require("illuminate").pause_buf()''}

              -- Disable line numbers and relative line numbers
              vim.cmd("setlocal nonumber norelativenumber")

              -- Disable matchparen
              vim.cmd("let g:loaded_matchparen = 1")

              -- Disable cursor line and column
              vim.cmd("setlocal nocursorline nocursorcolumn")

              -- Disable folding
              vim.cmd("setlocal nofoldenable")

              -- Disable sign column
              vim.cmd("setlocal signcolumn=no")

              -- Disable swap file and undo file
              vim.cmd("setlocal noswapfile noundofile")

              -- Отключить все автокоманды
              vim.cmd("autocmd!")

              -- Отключить все плагины
              vim.cmd("set rtp-=~/.config/nvim")
              vim.cmd("set rtp-=~/.local/share/nvim/site")

              -- Отключить подсветку синтаксиса
              vim.cmd("set synmaxcol=0")

              -- Установить минимальные настройки отображения
              vim.o.lazyredraw = true
              vim.o.redrawtime = 1000
              vim.o.scrolljump = 5
            end
          end
        '';
    }
  ];
}
