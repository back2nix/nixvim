{
  extraConfigVim = ''
    if &diff
      colorscheme desert
    endif
  '';

  extraConfigLuaPost = ''
    vim.opt.diffopt:append('internal,algorithm:patience,indent-heuristic')
  '';

  # Встроенные схемы:
  # default
  # blue
  # darkblue
  # delek
  # desert +
  # elflord
  # evening
  # industry
  # koehler
  # morning
  # murphy +
  # pablo
  # peachpuff
  # ron
  # shine
  # slate +
  # torte ++
  # zellner

  # Популярные схемы сообщества:

  # gruvbox
  # solarized
  # nord
  # dracula
  # monokai
  # onedark
  # tokyonight
}
