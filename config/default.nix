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

    ./plugins-more.nix

    ./plugins/persistent-breakpoints.nvim.nix
    ./plugins/git-blame.nvim.nix
    ./plugins/buffer.nix
    ./plugins/oil.nix
    ./plugins/git-worktree.nix
    ./plugins/spell.nix
    ./plugins/cmp-go-pkgs.nix

    ./plugins/ui/telescope.nix
    # ./plugins/ui/nvim-notify.nix
    ./plugins/utils/undotree.nix
    ./plugins/snippets/luasnip.nix
    # ./plugins/utils/hardtime.nix
    ./plugins/utils/gitlinker.nix

    # ./plugins/treesitter/treesitter.nix
    # ./plugins/treesitter/treesitter-context.nix
    # ./plugins/treesitter/treesitter-textobjects.nix
  ];

  options = {
  };
  config = {
    # colorschemes.gruvbox.enable = true;
    # colorschemes.dracula.enable = true;
    colorschemes.nightfox.enable = true;

    clipboard = {
      register = "unnamedplus";
      # TODO: Make conditional if X11/Wayland enabled
      # providers.wl-copy.enable = true;
      providers.xclip.enable = pkgs.stdenv.isLinux;
      providers.xsel.enable = pkgs.stdenv.isDarwin;
    };

    extraConfigLua = ''
      vim.api.nvim_set_keymap("x", "<C-t>", ":po<CR>", { noremap = true })

      local dap, dapui = require("dap"), require("dapui")
      require('dap.ext.vscode').load_launchjs()
      dap.listeners.before.attach.dapui_config = function()
      dapui.open()
      end
      dap.listeners.before.launch.dapui_config = function()
      dapui.open()
      end
      dap.listeners.before.event_terminated.dapui_config = function()
      dapui.close()
      end
      dap.listeners.before.event_exited.dapui_config = function()
      dapui.close()
      end

      require('dap-python').test_runner = "pytest"
    '';

    extraPlugins = with pkgs-master.vimPlugins; [
      # nvim-gdb
      vim-nix
      vim-dadbod
      vim-dadbod-ui
      vim-dadbod-completion
      dressing-nvim
      jupytext-nvim
    ];
    extraPackages = with pkgs-master; [
      fd
      ripgrep
      sqls
    ];
    globals = {
      mapleader = " ";
      maplocalleader = ",";
    };

    opts = {
      timeoutlen = 100;
      background = "";
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
