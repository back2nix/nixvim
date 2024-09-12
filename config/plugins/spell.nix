{
  inputs,
  pkgs,
  config,
  ...
}: let
  # nvim-spell-ru-utf8-dictionary = builtins.fetchurl {
  #   url = "http://ftp.vim.org/vim/runtime/spell/ru.utf-8.spl";
  #   sha256 = "0kf5vbk7lmwap1k4y4c1fm17myzbmjyzwz0arh5v6810ibbknbgb";
  # };
  # nvim-spell-ru-utf8-suggestions = builtins.fetchurl {
  #   url = "http://ftp.vim.org/vim/runtime/spell/ru.utf-8.sug";
  #   sha256 = "0frrdxhp37f8xi4wp6f2mxs07arbk3vqr038h3xmnpfqi8b8dgga";
  # };
  # nvim-spell-en-utf8-dictionary = builtins.fetchurl {
  #   url = "http://ftp.vim.org/vim/runtime/spell/en.utf-8.spl";
  #   sha256 = "0w1h9lw2c52is553r8yh5qzyc9dbbraa57w9q0r9v8xn974vvjpy";
  # };
  # nvim-spell-en-utf8-suggestions = builtins.fetchurl {
  #   url = "http://ftp.vim.org/vim/runtime/spell/en.utf-8.sug";
  #   sha256 = "1v1jr4rsjaxaq8bmvi92c93p4b14x2y1z95zl7bjybaqcmhmwvjv";
  # };
  # variant 1
  nvimSpell = pkgs.stdenv.mkDerivation {
    name = "nvim-spell";
    src = ./.;
    buildPhase = "mkdir -p $out/spell";
    installPhase = ''
      mkdir -p $out/spell
      ln -s ${inputs.nvim-spell-ru-utf8-dictionary} $out/spell/ru.utf-8.spl
      ln -s ${inputs.nvim-spell-ru-utf8-suggestions} $out/spell/ru.utf-8.sug
      ln -s ${inputs.nvim-spell-en-utf8-dictionary} $out/spell/en.utf-8.spl
      ln -s ${inputs.nvim-spell-en-utf8-suggestions} $out/spell/en.utf-8.sug
    '';
  };
in {
  extraConfigLua = ''
    vim.opt.runtimepath:append("${nvimSpell}")
      vim.opt.spelllang = { "en", "ru" }
      vim.opt.spell = true
      vim.opt.spellfile = {
        vim.fn.stdpath("config") .. "/spell/en.utf-8.add",
        vim.fn.stdpath("config") .. "/spell/ru.utf-8.add"
      }
  '';

  # not work
  # extraFiles = {
  # "/spell/ru.utf-8.spl" = builtins.readFile "${nvimSpell}/spell/ru.utf-8.spl";
  # "/spell/ru.utf-8.sug" = builtins.readFile "${inputs.nvim-spell-ru-utf8-suggestions}";
  # "/spell/en.utf-8.spl" = builtins.readFile "${inputs.nvim-spell-en-utf8-dictionary}";
  # "/spell/en.utf-8.sug" = builtins.readFile "${inputs.nvim-spell-en-utf8-suggestions}";
  # };

  # Отключение проверки орфографии для YAML файлов
  autoCmd = [
    {
      event = "FileType";
      pattern = ["yaml"];
      callback.__raw = ''
        function()
          vim.opt_local.spell = false
        end
      '';
    }
  ];
}
