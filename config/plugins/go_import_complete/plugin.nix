{pkgs, ...}: let
  go_import_complete = pkgs.callPackage ./default.nix {};

  go_import_complete-nvim = pkgs.vimUtils.buildVimPlugin {
    pname = go_import_complete.pname;
    version = go_import_complete.version;
    src = go_import_complete;

    buildPhase = ":";
    installPhase = ''
      mkdir -p $out/{bin,plugin}
      cp ${go_import_complete}/bin/${go_import_complete.pname} $out/bin/
      cp ${go_import_complete}/plugin/hello.lua $out/plugin/hello.lua
    '';
  };
in {
  extraPlugins = [go_import_complete-nvim];
  extraPackages = [go_import_complete];

  extraConfigLua = ''
    vim.env.PATH = vim.env.PATH .. ':' .. vim.fn.stdpath('data') .. '/plugged/go_import_complete/bin'
  '';
}
