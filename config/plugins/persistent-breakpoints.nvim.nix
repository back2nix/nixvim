{pkgs, ...}: let
  persistent-breakpoints-nvim = pkgs.vimUtils.buildVimPlugin {
    pname = "persistent-breakpoints.nvim";
    version = "2024-05-04";
    src = pkgs.fetchFromGitHub {
      owner = "back2nix";
      repo = "persistent-breakpoints.nvim";
      rev = "49ce24d2968e84595e9a8215adfeb37fd65690ea";
      sha256 = "sha256-euwc9XD02g8W52Z8SzjSInLnatS3aGLY44Frvd+yDTc=";
    };
    meta.homepage = "https://github.com/back2nix/persistent-breakpoints.nvim";

    # ----> ДОБАВЬТЕ ЭТУ СТРОКУ <----
    # Отключаем проверку, так как она не может найти nvim-dap во время сборки.
    doCheck = false;
  };
in {
  extraPlugins = [persistent-breakpoints-nvim];

  # Остальная часть файла остается без изменений
  keymaps = [
    {
      mode = ["n"];
      key = "<leader>dC";
      action.__raw = ''
        function()
        require("persistent-breakpoints.api").set_conditional_breakpoint()
        end
      '';
      options = {
        desc = "Set conditional breakpoint";
        silent = true;
      };
    }
    {
      mode = ["n"];
      key = "<S-F9>";
      action.__raw = ''
        function()
        require("persistent-breakpoints.api").set_conditional_breakpoint()
        end
      '';
      options = {
        desc = "Set conditional breakpoint";
        silent = true;
      };
    }
    {
      key = "<F9>";
      action.__raw = ''function() require('persistent-breakpoints.api').toggle_breakpoint() end'';
      options = {
        desc = "Toggle breakpoint";
        silent = true;
      };
    }
    {
      mode = ["n"];
      key = "<leader>db";
      action.__raw = ''function() require('persistent-breakpoints.api').toggle_breakpoint() end'';
      options = {
        desc = "Set breakpoint";
        silent = true;
      };
    }
    {
      mode = ["n"];
      key = "<leader>dB";
      action.__raw = ''function() require("persistent-breakpoints.api").clear_all_breakpoints() end'';
      options = {
        desc = "Clear all breakpoints";
        silent = true;
      };
    }
    {
      key = "<leader>dp";
      action = ":lua require('persistent-breakpoints.api').set_log_point()<CR>";
      options = {
        desc = "DapLogPoint";
        silent = true;
      };
    }
  ];

  extraConfigLua = ''
    require("persistent-breakpoints").setup({
      load_breakpoints_event = { "BufReadPost" }
    })
  '';
}
