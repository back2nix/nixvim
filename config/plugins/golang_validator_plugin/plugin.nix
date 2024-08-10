{pkgs, ...}: let
  golang_validator_plugin = pkgs.callPackage ./default.nix {};

  golang_validator_plugin-nvim = pkgs.vimUtils.buildVimPlugin {
    pname = golang_validator_plugin.pname;
    version = golang_validator_plugin.version;
    src = golang_validator_plugin;

    buildPhase = ":";
    installPhase = ''
      mkdir -p $out/{bin,plugin}
      cp ${golang_validator_plugin}/bin/${golang_validator_plugin.pname} $out/bin/
      cp ${golang_validator_plugin}/plugin/golang_validator_plugin.lua $out/plugin/golang_validator_plugin.lua
    '';
  };
in {
  extraPlugins = [golang_validator_plugin-nvim];
  extraPackages = [golang_validator_plugin];

  extraConfigLua = ''
    vim.env.PATH = vim.env.PATH .. ':' .. vim.fn.stdpath('data') .. '/plugged/golang_validator_plugin/bin'
  '';

  keymaps = [
    {
      mode = ["n"];
      key = "<leader>mv";
      action = ":AddValidatorTags<CR>";
      options = {
        desc = "Add import for word under cursor";
        silent = true;
      };
    }
  ];
}
