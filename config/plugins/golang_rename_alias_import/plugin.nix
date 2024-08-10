{pkgs, ...}: let
  golang_rename_alias_import = pkgs.callPackage ./default.nix {};

  golang_rename_alias_import-nvim = pkgs.vimUtils.buildVimPlugin {
    pname = golang_rename_alias_import.pname;
    version = golang_rename_alias_import.version;
    src = golang_rename_alias_import;

    buildPhase = ":";
    installPhase = ''
      mkdir -p $out/{bin,plugin}
      cp ${golang_rename_alias_import}/bin/${golang_rename_alias_import.pname} $out/bin/
      cp ${golang_rename_alias_import}/plugin/golang_rename_alias_import.lua $out/plugin/golang_rename_import.lua
    '';
  };
in {
  extraPlugins = [golang_rename_alias_import-nvim];
  extraPackages = [golang_rename_alias_import];

  extraConfigLua = ''
    vim.env.PATH = vim.env.PATH .. ':' .. vim.fn.stdpath('data') .. '/plugged/golang_rename_alias_import/bin'
  '';

  keymaps = [
    {
      mode = ["n"];
      key = "<leader>mz";
      action = ":RenameAliasImport<CR>";
      options = {
        desc = "Rename alias import";
        silent = true;
      };
    }
  ];
}
