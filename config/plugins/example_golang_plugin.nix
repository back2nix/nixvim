{pkgs, ...}: let
  helloremote = pkgs.callPackage ./example_golang_plugin/default.nix {};

  helloremote-nvim = pkgs.vimUtils.buildVimPlugin {
    pname = helloremote.pname;
    version = helloremote.version;
    src = helloremote;

    buildPhase = ":";
    installPhase = ''
      mkdir -p $out/{bin,plugin}
      cp ${helloremote}/bin/${helloremote.pname} $out/bin/
      cp ${helloremote}/plugin/hello.lua $out/plugin/hello.lua
    '';
  };
in {
  extraPlugins = [helloremote-nvim];
  extraPackages = [helloremote];

  extraConfigLua = ''
    vim.env.PATH = vim.env.PATH .. ':' .. vim.fn.stdpath('data') .. '/plugged/helloremote/bin'
  '';

  keymaps = [
    {
      mode = ["n"];
      key = "<leader>hw";
      action = ":Hello world<CR>";
      options = {
        desc = "Say Hello world";
        silent = true;
      };
    }
  ];
}
