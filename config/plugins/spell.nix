{config, ...}: let
  nvim-spell-ru-utf8-dictionary = builtins.fetchurl {
    url = "http://ftp.vim.org/vim/runtime/spell/ru.utf-8.spl";
    sha256 = "0kf5vbk7lmwap1k4y4c1fm17myzbmjyzwz0arh5v6810ibbknbgb";
  };

  nvim-spell-ru-utf8-suggestions = builtins.fetchurl {
    url = "http://ftp.vim.org/vim/runtime/spell/ru.utf-8.sug";
    sha256 = "0frrdxhp37f8xi4wp6f2mxs07arbk3vqr038h3xmnpfqi8b8dgga";
  };

  nvim-spell-en-utf8-dictionary = builtins.fetchurl {
    url = "http://ftp.vim.org/vim/runtime/spell/en.utf-8.spl";
    sha256 = "0w1h9lw2c52is553r8yh5qzyc9dbbraa57w9q0r9v8xn974vvjpy";
  };

  nvim-spell-en-utf8-suggestions = builtins.fetchurl {
    url = "http://ftp.vim.org/vim/runtime/spell/en.utf-8.sug";
    sha256 = "1v1jr4rsjaxaq8bmvi92c93p4b14x2y1z95zl7bjybaqcmhmwvjv";
  };
in {
  home.file."${config.xdg.configHome}/nvim/spell/ru.utf-8.spl".source = nvim-spell-ru-utf8-dictionary;
  home.file."${config.xdg.configHome}/nvim/spell/ru.utf-8.sug".source = nvim-spell-ru-utf8-suggestions;

  home.file."${config.xdg.configHome}/nvim/spell/en.utf-8.spl".source = nvim-spell-en-utf8-dictionary;
  home.file."${config.xdg.configHome}/nvim/spell/en.utf-8.sug".source = nvim-spell-en-utf8-suggestions;
}
