{
  description = "A nixvim configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-master.url = "github:nixos/nixpkgs/master";
    nixvim.url = "github:nix-community/nixvim";
    flake-parts.url = "github:hercules-ci/flake-parts";

    nvim-spell-ru-utf8-dictionary = {
      url = "https://github.com/back2nix/nixvim/releases/download/0.0.0/ru.utf-8.spl";
      # url = "http://ftp.vim.org/vim/runtime/spell/ru.utf-8.spl";
      # url = "path:./spell/ru.utf-8/ru.utf-8.spl";
      flake = false;
    };
    nvim-spell-ru-utf8-suggestions = {
      url = "https://github.com/back2nix/nixvim/releases/download/0.0.0/ru.utf-8.sug";
      # url = "http://ftp.vim.org/vim/runtime/spell/ru.utf-8.sug";
      # url = "path:./spell/ru.utf-8/ru.utf-8.sug";
      flake = false;
    };
    nvim-spell-en-utf8-dictionary = {
      url = "https://github.com/back2nix/nixvim/releases/download/0.0.0/en.utf-8.spl";
      # url = "http://ftp.vim.org/vim/runtime/spell/en.utf-8.spl";
      # url = "path:./spell/en.utf-8/en.utf-8.spl";
      flake = false;
    };
    nvim-spell-en-utf8-suggestions = {
      url = "https://github.com/back2nix/nixvim/releases/download/0.0.0/en.utf-8.sug";
      # url = "http://ftp.vim.org/vim/runtime/spell/en.utf-8.sug";
      # url = "path:./spell/en.utf-8/en.utf-8.sug";
      flake = false;
    };
  };

  outputs = {
    nixvim,
    nixpkgs-master,
    flake-parts,
    ...
  } @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      perSystem = {
        pkgs,
        system,
        ...
      }: let
        overlays = [
          (self: super: {
          })
          (final: prev: {
            bashdbInteractive = final.bashdb.overrideAttrs {
              buildInputs = (prev.buildInputs or []) ++ [final.bashInteractive];
            };
          })
        ];
        pkgs = import inputs.nixpkgs {
          inherit system overlays;
          config.allowUnfree = true;
        };
        pkgs-master = import inputs.nixpkgs-master {
          inherit system overlays;
          config.allowUnfree = true;
        };

        nixvimLib = nixvim.lib.${system};
        nixvim' = nixvim.legacyPackages.${system};
        nixvimModule = {
          inherit pkgs;
          module = import ./config; # import the module directly
          # You can use `extraSpecialArgs` to pass additional arguments to your module files
          extraSpecialArgs = {
            inherit inputs pkgs-master;
          };
        };
        nvim = nixvim'.makeNixvimWithModule nixvimModule;
      in {
        checks = {
          # Run `nix flake check .` to verify that your config is not broken
          default = nixvimLib.check.mkTestDerivationFromNixvimModule nixvimModule;
        };

        packages = {
          # Lets you run `nix run .` to start nixvim
          default = nvim;
        };
      };
    };
}
