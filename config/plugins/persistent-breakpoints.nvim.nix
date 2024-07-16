{pkgs, ...}: let
  # https://github.com/kranners/jimbo/blob/bff324d165f4bbcba7d265c00aea4e72c0eec8b7/shared/modules/nixvim/plugins/default.nix#L20
  persistent-breakpoints-nvim = pkgs.vimUtils.buildVimPlugin {
    pname = "persistent-breakpoints.nvim";
    version = "2024-05-04";
    src = pkgs.fetchFromGitHub {
      owner = "Weissle";
      repo = "persistent-breakpoints.nvim";
      rev = "01e43512ef8d137f2b9e5c1c74fd35c37e787b59";
      sha256 = "sha256-TSnieTf1zLcS755DJ9ZxwREcm+MbGwMXUs4XOdqe0bM=";
    };
    meta.homepage = "https://github.com/Weissle/persistent-breakpoints.nvim";
  };
in {
  extraPlugins = [persistent-breakpoints-nvim];

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
        desc = "Установить условную точку останова";
        silent = true;
      };
    }
    {
      mode = ["n"];
      key = "<leader>db";
      action.__raw = ''function() require('persistent-breakpoints.api').toggle_breakpoint() end'';
      options = {
        desc = "Поставить breakpoint";
        silent = true;
      };
    }
    {
      mode = ["n"];
      key = "<leader>dB";
      action.__raw = ''function() require("persistent-breakpoints.api").clear_all_breakpoints() end'';
      options = {
        desc = "Очистить breakpoint";
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
