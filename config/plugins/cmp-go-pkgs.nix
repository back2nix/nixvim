{pkgs, ...}: let
  # https://github.com/kranners/jimbo/blob/bff324d165f4bbcba7d265c00aea4e72c0eec8b7/shared/modules/nixvim/plugins/default.nix#L20
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
  ];

  keymaps = [
  ];

  extraConfigLua = ''
    local cmp = require("cmp")

    cmp.setup({
      sources = {
        { name = "go_pkgs" },
      },
      matching = { disallow_symbol_nonprefix_matching = false }, -- to use . and / in urls
    })
  '';
}
