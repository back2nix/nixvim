{pkgs, ...}: {
  # Здесь мы просто включаем плагин и указываем, откуда брать сниппеты
  plugins.luasnip = {
    enable = true;
    fromVscode = [
      {
        lazyLoad = true;
        paths = "${pkgs.vimPlugins.friendly-snippets}";
      }
    ];
  };

  # А здесь мы добавляем Lua-код для его настройки
  extraConfigLua = ''
    require("luasnip").setup({
      enable_autosnippets = true,
      store_selection_keys = "<Tab>",
    })
  '';
}
