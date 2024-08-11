{pkgs, ...}: let
  golang_rename_alias_import_nvim = pkgs.callPackage ./default.nix {};

  golang_rename_alias_import_nvim-nvim = pkgs.vimUtils.buildVimPlugin {
    pname = golang_rename_alias_import_nvim.pname;
    version = golang_rename_alias_import_nvim.version;
    src = golang_rename_alias_import_nvim;

    buildPhase = ":";
    installPhase = ''
      mkdir -p $out/{bin,plugin}
      cp ${golang_rename_alias_import_nvim}/bin/${golang_rename_alias_import_nvim.pname} $out/bin/
      cp ${golang_rename_alias_import_nvim}/plugin/hello.lua $out/plugin/golang_rename_import.lua
    '';
  };
in {
  extraPlugins = [golang_rename_alias_import_nvim-nvim];
  extraPackages = [golang_rename_alias_import_nvim];

  extraConfigLua = ''
    vim.env.PATH = vim.env.PATH .. ':' .. vim.fn.stdpath('data') .. '/plugged/golang_rename_alias_import_nvim/bin'
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
