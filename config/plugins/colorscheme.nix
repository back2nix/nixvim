{inputs, ...}: {
  colorschemes = {
    catppuccin = {
      enable = true;
      flavour = "mocha";
      showBufferEnd = true;
      transparentBackground = false;
      integrations = {
        cmp = true;
        # dashboard = true;
        fidget = true;
        # gitgutter = true;
        # gitsigns = true;
        # harpoon = true;
        # hop = true;
        # neogit = true;
        # neotree = true;
        noice = true;
        # notifier = true;
        notify = true;
        # nvimtree = true;
        treesitter = true;
        treesitter_context = true;
        ts_rainbow = true;
        # ts_rainbow2 = true;
        # ufo = true;
        which_key = true;
        window_picker = true;

        dap = {
          enable_ui = true;
          enabled = true;
        };

        indent_blankline = {
          enabled = true;
          colored_indent_levels = true;
        };

        native_lsp.enabled = true;

        navic.enabled = true;

        telescope = {
          enabled = true;
        };
      };
    };
  };
}
