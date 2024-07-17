{
  autoCmd = [
    # Vertically center document when entering insert mode
    {
      event = "InsertEnter";
      command = "norm zz";
    }

    # Open help in a vertical split
    {
      event = "FileType";
      pattern = "help";
      command = "wincmd L";
    }

    # Enable spellcheck for some filetypes
    {
      event = "FileType";
      pattern = [
        "tex"
        "latex"
        "markdown"
      ];
      command = "setlocal spell spelllang=en,fr";
    }
    {
      event = "FileType";
      pattern = ["sql" "mysql" "plsql"];
      command = "lua require('cmp').setup.buffer({ sources = {{ name = 'vim-dadbod-completion' }} })";
    }
  ];
}
