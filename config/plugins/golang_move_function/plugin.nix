{pkgs, ...}: let
  golang_move_function = pkgs.callPackage ./default.nix {};

  golang_move_function-nvim = pkgs.vimUtils.buildVimPlugin {
    pname = golang_move_function.pname;
    version = golang_move_function.version;
    src = golang_move_function;

    buildPhase = ":";
    installPhase = ''
      mkdir -p $out/{bin,plugin}
      cp ${golang_move_function}/bin/${golang_move_function.pname} $out/bin/
      cp ${golang_move_function}/plugin/hello.lua $out/plugin/hello.lua
    '';
  };
in {
  extraPlugins = [golang_move_function-nvim];
  extraPackages = [golang_move_function];

  extraConfigLua = ''
    vim.env.PATH = vim.env.PATH .. ':' .. vim.fn.stdpath('data') .. '/plugged/golang_move_function/bin'
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
