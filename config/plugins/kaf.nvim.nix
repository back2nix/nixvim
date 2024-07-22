{pkgs, ...}: let
  kaf-nvim = pkgs.vimUtils.buildVimPlugin {
    pname = "kaf.nvim";
    version = "2024-07-22";
    src = pkgs.fetchFromGitHub {
      owner = "kessejones";
      repo = "kaf.nvim";
      rev = "main"; # Вы можете заменить это на конкретный коммит или тег
      sha256 = "sha256-1iRiJXzjfYZRfjA4GjdLEP7D9mI/9Vs1tjV/mZveA1s="; # Замените это на актуальный хеш
    };
    meta.homepage = "https://github.com/kessejones/kaf.nvim";
  };
in {
  extraPlugins = [
    kaf-nvim
    pkgs.vimPlugins.plenary-nvim
    pkgs.vimPlugins.telescope-nvim
    pkgs.vimPlugins.fidget-nvim # опционально
  ];

  keymaps = [
    {
      mode = ["n"];
      key = "<leader>ke";
      action.__raw = ''
        function()
          require("kaf.integrations.telescope").clients()
        end
      '';
      options = {
        desc = "List clients entries";
        silent = true;
      };
    }
    {
      mode = ["n"];
      key = "<leader>kt";
      action.__raw = ''
        function()
          require("kaf.integrations.telescope").topics()
        end
      '';
      options = {
        desc = "List topics from selected client";
        silent = true;
      };
    }
    {
      mode = ["n"];
      key = "<leader>km";
      action.__raw = ''
        function()
          require("kaf.integrations.telescope").messages()
        end
      '';
      options = {
        desc = "List messages from selected topic and client";
        silent = true;
      };
    }
    {
      mode = ["n"];
      key = "<leader>kp";
      action.__raw = ''
        function()
          require("kaf.api").produce({ value_from_buffer = true })
        end
      '';
      options = {
        desc = "Produce a message into selected topic and client";
        silent = true;
      };
    }
  ];

  extraConfigLua = ''
    require('kaf').setup({
      integrations = {
        fidget = true,
      },
      confirm_on_produce_message = true,
    })
  '';
}
