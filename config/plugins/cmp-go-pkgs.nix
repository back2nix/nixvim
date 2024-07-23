{pkgs, ...}: let
  cmp-go-pkgs = pkgs.vimUtils.buildVimPlugin {
    pname = "cmp-go-pkgs";
    version = "2024-05-04";
    src = pkgs.fetchFromGitHub {
      owner = "Snikimonkd";
      repo = "cmp-go-pkgs";
      rev = "7a76e1f9c8d5f40fe27b8d6fcac04de4456875bb";
      sha256 = "sha256-pB7hz/md/5NVYE2FJLNcFkVfUkIxfqr1bJrCtlnIW7w=";
    };
    meta.homepage = "https://github.com/Snikimonkd/cmp-go-pkgs";
  };
in {
  extraPlugins = [
    cmp-go-pkgs
    pkgs.vimPlugins.nvim-cmp
    pkgs.vimPlugins.lspkind-nvim
  ];
  keymaps = [];
  extraConfigLua = ''
    local cmp = require("cmp")
    cmp.setup({
      snippet = {
        expand = function(args)
          require('luasnip').lsp_expand(args.body)
        end,
      },
      mapping = {
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<CR>'] = cmp.mapping.confirm(),
        ['<ESC>'] = cmp.mapping.close(),
        ['<Down>'] = cmp.mapping.select_next_item(),
        ['<C-j>'] = cmp.mapping.select_next_item(),
        ['<Tab>'] = cmp.mapping.select_next_item(),
        ['<Up>'] = cmp.mapping.select_prev_item(),
        ['<C-k>'] = cmp.mapping.select_prev_item(),
        ['<S-Tab>'] = cmp.mapping.select_prev_item(),
      },
      sources = cmp.config.sources({
        {name = "path"},
        {name = "nvim_lsp"},
        {name = "cmp_tabby"},
        {name = "luasnip"},
        {name = "buffer", option = {get_bufnrs = vim.api.nvim_list_bufs}},
        {name = "neorg"},
        {name = "nvim_lsp_signature_help"},
        {name = "treesitter"},
        {name = "dap"},
        {name = "go_pkgs"},
      }),
    })

    -- Специфичная настройка для Go файлов
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "go",
      callback = function()
        cmp.setup.buffer({
          sources = cmp.config.sources(
            {{name = "go_pkgs"}},
            cmp.config.sources()  -- Это включает все ранее настроенные источники
          ),
          matching = {disallow_symbol_nonprefix_matching = false},
        })
      end,
    })

    -- Настройка lspkind
    local lspkind = require('lspkind')
    cmp.setup {
      formatting = {
        format = lspkind.cmp_format({
          mode = 'symbol_text',
          menu = {
            nvim_lsp = "[LSP]",
            nvim_lua = "[api]",
            path = "[path]",
            luasnip = "[snip]",
            buffer = "[buffer]",
            dap = "[dap]",
            treesitter = "[treesitter]",
            cmp_tabby = "[Tabby]",
            go_pkgs = "[pkgs]",
          }
        })
      }
    }
  '';
}
