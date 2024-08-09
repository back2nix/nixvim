{pkgs, ...}: let
  go_import_plugin = pkgs.callPackage ./default.nix {};

  go_import_plugin-nvim = pkgs.vimUtils.buildVimPlugin {
    pname = go_import_plugin.pname;
    version = go_import_plugin.version;
    src = go_import_plugin;

    buildPhase = ":";
    installPhase = ''
      mkdir -p $out/{bin,plugin}
      cp ${go_import_plugin}/bin/${go_import_plugin.pname} $out/bin/
      cp ${go_import_plugin}/plugin/go_import_plugin.lua $out/plugin/go_import_plugin.lua
    '';
  };
in {
  extraPlugins = [go_import_plugin-nvim];
  extraPackages = [go_import_plugin];

  extraConfigLua = ''
    vim.env.PATH = vim.env.PATH .. ':' .. vim.fn.stdpath('data') .. '/plugged/go_import_plugin/bin'
  '';

  keymaps = [
    {
      mode = ["n"];
      key = "<leader>mi";
      action = ":AddImport<CR>";
      options = {
        desc = "Add import for word under cursor";
        silent = true;
      };
    }
  ];
}
