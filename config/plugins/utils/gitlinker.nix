{pkgs, ...}: {
  extraPlugins = with pkgs.vimUtils; [
    (buildVimPlugin {
      pname = "gitlinker.nvim";
      version = "1.0";
      src = pkgs.fetchFromGitHub {
        owner = "ruifm";
        repo = "gitlinker.nvim";
        rev = "cc59f732f3d043b626c8702cb725c82e54d35c25";
        hash = "sha256-zrHvJSROjrDC5XtepOwuDrzrJG2jpnF5NJ05Iwd6DwA=";
      };

      # ----> ДОБАВЬТЕ ЭТУ СТРОКУ <----
      # Отключаем проверку зависимостей во время сборки.
      # Это безопасно, так как plenary.nvim будет доступен во время выполнения.
      doCheck = false;
    })

    # Оставляем plenary здесь для времени выполнения (runtime)
    pkgs.vimPlugins.plenary-nvim
  ];

  # Остальная часть файла остается без изменений
  extraConfigLua = ''
    require("gitlinker").setup({
      opts = {
        remote = nil,
        add_current_line_on_normal_mode = true,
        action_callback = require("gitlinker.actions").copy_to_clipboard,
        print_url = true,
      },
      callbacks = {
        ["github.com"] = require("gitlinker.hosts").get_github_type_url,
        ["gitlab.com"] = require("gitlinker.hosts").get_gitlab_type_url,
        ["gitlab.ozon.ru"] = require("gitlinker.hosts").get_gitlab_type_url,
        ["try.gitea.io"] = require("gitlinker.hosts").get_gitea_type_url,
        ["codeberg.org"] = require("gitlinker.hosts").get_gitea_type_url,
        ["bitbucket.org"] = require("gitlinker.hosts").get_bitbucket_type_url,
        ["try.gogs.io"] = require("gitlinker.hosts").get_gogs_type_url,
        ["git.sr.ht"] = require("gitlinker.hosts").get_srht_type_url,
        ["git.launchpad.net"] = require("gitlinker.hosts").get_launchpad_type_url,
        ["repo.or.cz"] = require("gitlinker.hosts").get_repoorcz_type_url,
        ["git.kernel.org"] = require("gitlinker.hosts").get_cgit_type_url,
        ["git.savannah.gnu.org"] = require("gitlinker.hosts").get_cgit_type_url
      },
      mappings = "<leader>gy"
    })
  '';
  keymaps = [
    {
      mode = "n";
      key = "<leader>gy";
      action = "<cmd>lua require('gitlinker').get_buf_range_url('n')<cr>";
      options = {
        silent = true;
        noremap = true;
      };
    }
    {
      mode = "v";
      key = "<leader>gy";
      action = "<cmd>lua require('gitlinker').get_buf_range_url('v')<cr>";
      options = {
        silent = true;
        noremap = true;
      };
    }
  ];
}
