{pkgs, ...}: let
  telescope-hierarchy = pkgs.vimUtils.buildVimPlugin {
    pname = "telescope-hierarchy";
    version = "2024-02-16";
    src = pkgs.fetchFromGitHub {
      owner = "jmacadie";
      repo = "telescope-hierarchy.nvim";
      rev = "20dcc78180a322e9617d5f86aef3838b8bf03b7f";
      sha256 = "sha256-WhF/fMqmbjSaZ6/c8bbuCChfMvlSiHDKawcS8IMjh3A=";
    };
    meta.homepage = "https://github.com/jmacadie/telescope-hierarchy.nvim";
  };
in {
  extraPlugins = [telescope-hierarchy];
  extraConfigLua = ''
    require('telescope').load_extension('hierarchy')
  '';
}
