{pkgs, ...}: let
  # https://github.com/kranners/jimbo/blob/bff324d165f4bbcba7d265c00aea4e72c0eec8b7/shared/modules/nixvim/plugins/default.nix#L20
  nvim-dbee = pkgs.vimUtils.buildVimPlugin {
    pname = "nvim-dbee";
    version = "2024-05-04";
    src = pkgs.fetchFromGitHub {
      owner = "kndndrj";
      repo = "nvim-dbee";
      rev = "cf729a95dce66d48f1041c96231b8a205969feb1";
      sha256 = "sha256-8xBpagFhzMAn00UDvURF1iIbU3hSUkZxERh6WBlTuCI=";
    };
    meta.homepage = "https://github.com/kndndrj/nvim-dbee";
  };
in {
  extraPlugins = [nvim-dbee];

  keymaps = [
    {
      mode = ["n"];
      key = "<leader>bo";
      action.__raw = ''function() require("dbee").open() end'';
      options = {
        desc = "Open dbee ui";
        silent = true;
      };
    }
  ];

  extraConfigLua = ''
    require("dbee").setup(--[[optional config]])
  '';
}
