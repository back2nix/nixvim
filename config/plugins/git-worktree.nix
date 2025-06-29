{
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf;

  cfg = config.plugins.git-worktree;
in {
  plugins = {
    git-worktree = {
      enable = true;
      enableTelescope = true;
    };

    # ИСПРАВЛЕНО: `registrations` устарело. Используем `settings.spec` для определения группы.
    which-key.settings.spec = mkIf (cfg.enableTelescope && cfg.enable) [
      {
        mode = "n";
        key = "<leader>gW";
        group = "󰙅 Worktree";
      }
    ];
  };

  keymaps = mkIf cfg.enableTelescope [
    {
      mode = "n";
      key = "<leader>fg";
      action = ":Telescope git_worktree<CR>";
      options = {
        desc = "Git Worktree";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>gWc";
      action.__raw =
        # lua
        ''
          function()
            require('telescope').extensions.git_worktree.create_git_worktree()
          end
        '';
      options = {
        desc = "Create worktree";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>gWs";
      action.__raw =
        # lua
        ''
          function()
            require('telescope').extensions.git_worktree.git_worktrees()
          end
        '';
      options = {
        desc = "Switch / Delete worktree";
        silent = true;
      };
    }
  ];
}
