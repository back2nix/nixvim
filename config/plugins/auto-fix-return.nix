{pkgs, ...}: let
  # https://github.com/kranners/jimbo/blob/bff324d165f4bbcba7d265c00aea4e72c0eec8b7/shared/modules/nixvim/plugins/default.nix#L20
  auto-fix-return-nvim = pkgs.vimUtils.buildVimPlugin {
    pname = "auto-fix-return-nvim";
    version = "2024-09-13";
    src = pkgs.fetchFromGitHub {
      owner = "Jay-Madden";
      repo = "auto-fix-return.nvim";
      rev = "f6e81ec27acee1f9ce52522d051e63cd2c116ac1";
      sha256 = "sha256-H4YYq9lzFhvfkriPOw0vdtXVAAjbtVzDSL2YjlXCyN4=";
    };
    meta.homepage = "https://github.com/Jay-Madden/auto-fix-return.nvim";
  };
in {
  extraPlugins = [auto-fix-return-nvim];

  keymaps = [
  ];

  extraConfigLua = ''
    require('auto-fix-return').setup({})
  '';
}
