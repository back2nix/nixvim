{pkgs, ...}: let
  cmp-go-pkgs = pkgs.vimUtils.buildVimPlugin {
    pname = "cmp-go-pkgs";
    version = "2024-05-04";
    src = pkgs.fetchFromGitHub {
      owner = "Snikimonkd";
      repo = "cmp-go-pkgs";
      rev = "7a76e1f9c8d5f40fe27b8d6fcac04de4456875bb";
      sha256 = "sha256-pB7hz/md/5NVYE2FJLNcFkVfUkIxfqr1bJrCtlnIW7w=";
    };
    meta.homepage = "https://github.com/Snikimonkd/cmp-go-pkgs";
  };
in {
  extraPlugins = [
    cmp-go-pkgs
    pkgs.vimPlugins.nvim-cmp
  ];
  keymaps = [
  ];
  extraConfigLua = ''
    local cmp = require("cmp")

    vim.api.nvim_create_autocmd("FileType", {
      pattern = "go",
      callback = function()
        cmp.setup.buffer({
          sources = {
            { name = "go_pkgs" },
          },
          matching = { disallow_symbol_nonprefix_matching = false },
        })
      end,
    })

    cmp.setup({
      -- Your global cmp setup (if any) goes here
    })
  '';
}
