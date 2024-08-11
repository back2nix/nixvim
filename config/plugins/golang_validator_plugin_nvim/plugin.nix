{pkgs, ...}: let
  golang_validator_plugin_nvim = pkgs.callPackage ./default.nix {};

  golang_validator_plugin_nvim-nvim = pkgs.vimUtils.buildVimPlugin {
    pname = golang_validator_plugin_nvim.pname;
    version = golang_validator_plugin_nvim.version;
    src = golang_validator_plugin_nvim;

    buildPhase = ":";
    installPhase = ''
      mkdir -p $out/{bin,plugin}
      cp ${golang_validator_plugin_nvim}/bin/${golang_validator_plugin_nvim.pname} $out/bin/
      cp ${golang_validator_plugin_nvim}/plugin/hello.lua $out/plugin/hello.lua
    '';
  };
in {
  extraPlugins = [golang_validator_plugin_nvim-nvim];
  extraPackages = [golang_validator_plugin_nvim];

  extraConfigLua = ''
    vim.env.PATH = vim.env.PATH .. ':' .. vim.fn.stdpath('data') .. '/plugged/golang_validator_plugin_nvim/bin'
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
