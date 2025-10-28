{
  inputs,
  config,
  pkgs,
  pkgs-master,
  lib,
  ...
}: let
in {
  imports = [
    ./autocommands.nix
    ./user-commands.nix
    ./keys.nix
    ./plugins/diff.nix

    # ./plugins/cmp-go-pkgs.nix
    ./plugins-more.nix

    ./plugins/dap.nix
    # ./plugins/nvim-dbee.nix
    ./plugins/mason-nvim.nix
    ./plugins/persistent-breakpoints.nvim.nix
    ./plugins/git-blame.nvim.nix
    ./plugins/telescope-hierarchy.nix
    ./plugins/buffer.nix
    ./plugins/oil.nix
    ./plugins/git-worktree.nix
    ./plugins/spell.nix
    # ./plugins/kaf.nvim.nix

    ./plugins/ui/telescope.nix
    # ./plugins/ui/nvim-notify.nix
    ./plugins/utils/undotree.nix
    ./plugins/snippets/luasnip.nix
    # ./plugins/utils/hardtime.nix
    ./plugins/utils/gitlinker.nix
    # ./plugins/auto-fix-return.nix
    ./plugins/example_golang_plugin_nvim/plugin.nix
    ./plugins/golang_import_complete_nvim/plugin.nix
    ./plugins/golang_import_plugin_nvim/plugin.nix
    ./plugins/golang_validator_plugin_nvim/plugin.nix
    ./plugins/golang_rename_import_nvim/plugin.nix
    ./plugins/golang_rename_alias_import_nvim/plugin.nix
    ./plugins/golang_move_function_nvim/plugin.nix
    ./plugins/golang_arg_refactor_nvim/plugin.nix

    # ./plugins/treesitter/treesitter.nix
    # ./plugins/treesitter/treesitter-context.nix
    # ./plugins/treesitter/treesitter-textobjects.nix
  ];

  options = {};
  config = {
    # colorschemes.gruvbox.enable = true;
    # colorschemes.dracula.enable = true;
    colorschemes.nightfox.enable = true;

    clipboard = {
      register = "unnamedplus";
      providers = {
        # Для Wayland. Neovim выберет его автоматически, если доступен.
        wl-copy.enable = pkgs.stdenv.isLinux;

        # Для X11. Будет использован как запасной вариант, если wl-copy недоступен.
        xclip.enable = pkgs.stdenv.isLinux;

        # Для macOS.
        xsel.enable = pkgs.stdenv.isDarwin;
      };
    };

    extraConfigLua = ''
      vim.api.nvim_set_keymap("x", "<C-t>", ":po<CR>", { noremap = true })

      require('nvim-highlight-colors').setup({})
    '';

    extraPlugins = with pkgs-master.vimPlugins; [
      # nvim-gdb
      vim-nix
      vim-dadbod
      vim-dadbod-ui
      vim-dadbod-completion
      dressing-nvim
      jupytext-nvim
      treesj # split join
      nvim-highlight-colors
    ];
    extraPackages = with pkgs-master; [
      fd
      ripgrep
      sqls
      prettierd
      # nixfmt-rfc-style
      stylua
      ruff
      alejandra
      typescript
    ];
    globals = {
      mapleader = " ";
      maplocalleader = ",";
    };

    opts = {
      timeoutlen = 100;
      # background = "";
      updatetime = 100;
      grepprg = "rg --vimgrep";
      grepformat = "%f:%l:%c:%m";
      # spell = true;
      # spelllang = [] ++ lib.optional (builtins.pathExists (config.lib.file.mkOutOfStoreSymlink "~/nvim/spell/ru.utf-8.spl")) ["en" "ru"];
      # spelllang = [] ++ lib.optional (builtins.pathExists "~/nvim/spell/ru.utf-8.spl") ["en" "ru"];
      number = true; # Show line numbers
      relativenumber = true; # Show relative line numbers
      incsearch = true;
      expandtab = true;
      shiftwidth = 2; # Tab width should be 2
      tabstop = 2;
      termguicolors = true;
      ignorecase = true;
      smartcase = true;
      undofile = true;
      swapfile = false;
      list = true;
      listchars.__raw = "{ tab = '» ', trail = '·', nbsp = '␣' }";
      cursorline = true;
      hlsearch = true;
      breakindent = true;
    };

    luaLoader.enable = true;
  };
}
