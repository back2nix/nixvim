{pkgs, ...}: let
  # https://github.com/kranners/jimbo/blob/bff324d165f4bbcba7d265c00aea4e72c0eec8b7/shared/modules/nixvim/plugins/default.nix#L20
  mason-nvim = pkgs.vimUtils.buildVimPlugin {
    pname = "mason.nvim";
    version = "2024-05-04";
    src = pkgs.fetchFromGitHub {
      owner = "williamboman";
      repo = "mason.nvim";
      rev = "e2f7f9044ec30067bc11800a9e266664b88cda22";
      sha256 = "sha256-F0qsl8AL0hyq3WSVIIkxG4OHOar+3xHLZZ3RrVlk2mY=";
    };
    meta.homepage = "https://github.com/williamboman/mason.nvim";
  };
in {
  extraPlugins = [mason-nvim];

  keymaps = [
  ];

  extraConfigLua = ''
    require("mason").setup({
      ensure_installed = {
        "bash-debug-adapter",
      },
    })
  '';
}
