{pkgs, ...}: let
  golang_arg_refactor_nvim = pkgs.callPackage ./code/default.nix {};

  golang_arg_refactor_nvim-nvim = pkgs.vimUtils.buildVimPlugin {
    pname = golang_arg_refactor_nvim.pname;
    version = golang_arg_refactor_nvim.version;
    src = golang_arg_refactor_nvim;

    buildPhase = ":";
    installPhase = ''
      mkdir -p $out/{bin,plugin}
      cp ${golang_arg_refactor_nvim}/bin/${golang_arg_refactor_nvim.pname} $out/bin/
      cp ${golang_arg_refactor_nvim}/plugin/hello.lua $out/plugin/hello.lua
    '';
  };
in {
  extraPlugins = [golang_arg_refactor_nvim-nvim];
  extraPackages = [golang_arg_refactor_nvim];

  extraConfigLua = ''
    vim.env.PATH = vim.env.PATH .. ':' .. vim.fn.stdpath('data') .. '/plugged/golang_arg_refactor_nvim/bin'
  '';

  keymaps = [
    {
      mode = ["n"];
      key = "<leader>mF";
      action = ":MoveCode<CR>";
      options = {
        desc = "Move code";
        silent = true;
      };
    }
    {
      mode = ["n"];
      key = "<leader>r";
      action = ":RepeatMoveCode<CR>";
      options = {
        desc = "Repeat move";
        silent = true;
      };
    }
  ];
}
