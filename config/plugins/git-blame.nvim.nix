{pkgs, ...}: let
  # https://github.com/kranners/jimbo/blob/bff324d165f4bbcba7d265c00aea4e72c0eec8b7/shared/modules/nixvim/plugins/default.nix#L20
  blame-nvim = pkgs.vimUtils.buildVimPlugin {
    pname = "blame-nvim";
    version = "2024-05-04";
    src = pkgs.fetchFromGitHub {
      owner = "FabijanZulj";
      repo = "blame.nvim";
      rev = "dedbcdce857f708c63f261287ac7491a893912d0";
      sha256 = "sha256-dj9eQ3Nr38T4BZgqIexWCMPN2vLFNFqfyfdZGM6BBC4=";
    };
    meta.homepage = "https://github.com/FabijanZulj/blame.nvim";
  };
in {
  extraPlugins = [blame-nvim];

  keymaps = [
  ];

  extraConfigLua = ''
    require('blame').setup({})
  '';
}
