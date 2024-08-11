{pkgs, ...}: let
  golang_move_function_nvim = pkgs.callPackage ./default.nix {};

  golang_move_function_nvim-nvim = pkgs.vimUtils.buildVimPlugin {
    pname = golang_move_function_nvim.pname;
    version = golang_move_function_nvim.version;
    src = golang_move_function_nvim;

    buildPhase = ":";
    installPhase = ''
      mkdir -p $out/{bin,plugin}
      cp ${golang_move_function_nvim}/bin/${golang_move_function_nvim.pname} $out/bin/
      cp ${golang_move_function_nvim}/plugin/hello.lua $out/plugin/hello.lua
    '';
  };
in {
  extraPlugins = [golang_move_function_nvim-nvim];
  extraPackages = [golang_move_function_nvim];

  extraConfigLua = ''
    vim.env.PATH = vim.env.PATH .. ':' .. vim.fn.stdpath('data') .. '/plugged/golang_move_function_nvim/bin'
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
