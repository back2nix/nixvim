{pkgs, ...}: let
  golang_import_complete_nvim = pkgs.callPackage ./default.nix {};

  golang_import_complete_nvim-nvim = pkgs.vimUtils.buildVimPlugin {
    pname = golang_import_complete_nvim.pname;
    version = golang_import_complete_nvim.version;
    src = golang_import_complete_nvim;

    buildPhase = ":";
    installPhase = ''
      mkdir -p $out/{bin,plugin}
      cp ${golang_import_complete_nvim}/bin/${golang_import_complete_nvim.pname} $out/bin/
      cp ${golang_import_complete_nvim}/plugin/hello.lua $out/plugin/hello.lua
    '';
  };
in {
  extraPlugins = [golang_import_complete_nvim-nvim];
  extraPackages = [golang_import_complete_nvim];

  extraConfigLua = ''
    vim.env.PATH = vim.env.PATH .. ':' .. vim.fn.stdpath('data') .. '/plugged/golang_import_complete_nvim/bin'
  '';
}
