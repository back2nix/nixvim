{pkgs, ...}: let
  golang_rename_import = pkgs.callPackage ./default.nix {};

  golang_rename_import-nvim = pkgs.vimUtils.buildVimPlugin {
    pname = golang_rename_import.pname;
    version = golang_rename_import.version;
    src = golang_rename_import;

    buildPhase = ":";
    installPhase = ''
      mkdir -p $out/{bin,plugin}
      cp ${golang_rename_import}/bin/${golang_rename_import.pname} $out/bin/
      cp ${golang_rename_import}/plugin/golang_rename_import.lua $out/plugin/golang_rename_import.lua
    '';
  };
in {
  extraPlugins = [golang_rename_import-nvim];
  extraPackages = [golang_rename_import];

  extraConfigLua = ''
    vim.env.PATH = vim.env.PATH .. ':' .. vim.fn.stdpath('data') .. '/plugged/golang_rename_import/bin'
  '';

  keymaps = [
    {
      mode = ["n"];
      key = "<leader>mx";
      action = ":RenameImport<CR>";
      options = {
        desc = "Rename import";
        silent = true;
      };
    }
  ];
}
