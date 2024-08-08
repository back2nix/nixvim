{pkgs, ...}: let
  goimportcomplete = pkgs.callPackage ./default.nix {};

  goimportcomplete-nvim = pkgs.vimUtils.buildVimPlugin {
    pname = goimportcomplete.pname;
    version = goimportcomplete.version;
    src = goimportcomplete;

    buildPhase = ":";
    installPhase = ''
      mkdir -p $out/{bin,plugin}
      cp ${goimportcomplete}/bin/${goimportcomplete.pname} $out/bin/
      cp ${goimportcomplete}/plugin/hello.lua $out/plugin/hello.lua
    '';
  };
in {
  extraPlugins = [goimportcomplete-nvim];
  extraPackages = [goimportcomplete];

  extraConfigLua = ''
    vim.env.PATH = vim.env.PATH .. ':' .. vim.fn.stdpath('data') .. '/plugged/goimportcomplete/bin'
  '';

  # keymaps = [
  #   {
  #     mode = ["n"];
  #     key = "<leader>hw";
  #     action = ":Hello world<CR>";
  #     options = {
  #       desc = "Say Hello world";
  #       silent = true;
  #     };
  #   }
  # ];
}
