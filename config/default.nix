{
  inputs,
  config,
  pkgs,
  pkgs-master,
  lib,
  ...
}: let
in {
  imports = [
    ./autocommands.nix
    ./plugins/persistent-breakpoints.nvim.nix
    ./plugins/git-blame.nvim.nix
    ./plugins/buffer.nix
    ./plugins/oil.nix
    ./plugins/git-worktree.nix
    ./plugins/spell.nix
    ./plugins/cmp-go-pkgs.nix

    ./plug/ui/telescope.nix
    ./plug/utils/undotree.nix
    # ./plug/ui/nvim-notify.nix
    ./plug/git/gitlinker.nix
    ./plug/snippets/luasnip.nix
    # ./plug/treesitter/treesitter.nix
    # ./plug/treesitter/treesitter-context.nix
    # ./plug/treesitter/treesitter-textobjects.nix

    ./userCommands.nix
    ./keys.nix
  ];

  options = {
  };
  config = {
    # colorschemes.gruvbox.enable = true;
    # colorschemes.dracula.enable = true;
    colorschemes.nightfox.enable = true;

    clipboard = {
      register = "unnamedplus";
      # TODO: Make conditional if X11/Wayland enabled
      # providers.wl-copy.enable = true;
      providers.xclip.enable = pkgs.stdenv.isLinux;
      providers.xsel.enable = pkgs.stdenv.isDarwin;
    };

    extraConfigLua = ''
      vim.api.nvim_set_keymap("x", "<C-t>", ":po<CR>", { noremap = true })

      local dap, dapui = require("dap"), require("dapui")
      require('dap.ext.vscode').load_launchjs()
      dap.listeners.before.attach.dapui_config = function()
      dapui.open()
      end
      dap.listeners.before.launch.dapui_config = function()
      dapui.open()
      end
      dap.listeners.before.event_terminated.dapui_config = function()
      dapui.close()
      end
      dap.listeners.before.event_exited.dapui_config = function()
      dapui.close()
      end

      require('dap-python').test_runner = "pytest"
    '';

    extraPlugins = with pkgs-master.vimPlugins; [
      # nvim-gdb
      vim-nix
      vim-dadbod
      vim-dadbod-ui
      vim-dadbod-completion
      dressing-nvim
      jupytext-nvim
    ];
    extraPackages = with pkgs-master; [
      fd
      ripgrep
      sqls
    ];
    globals = {
      mapleader = " ";
      maplocalleader = ",";
    };

    opts = {
      timeoutlen = 100;
      background = "";
      updatetime = 100;
      grepprg = "rg --vimgrep";
      grepformat = "%f:%l:%c:%m";
      # spell = true;
      # spelllang = [] ++ lib.optional (builtins.pathExists (config.lib.file.mkOutOfStoreSymlink "~/nvim/spell/ru.utf-8.spl")) ["en" "ru"];
      # spelllang = [] ++ lib.optional (builtins.pathExists "~/nvim/spell/ru.utf-8.spl") ["en" "ru"];
      number = true; # Show line numbers
      relativenumber = true; # Show relative line numbers
      incsearch = true;
      expandtab = true;
      shiftwidth = 2; # Tab width should be 2
      tabstop = 2;
      termguicolors = true;
      ignorecase = true;
      smartcase = true;
      undofile = true;
      swapfile = false;
      list = true;
      listchars.__raw = "{ tab = '» ', trail = '·', nbsp = '␣' }";
      cursorline = true;
      hlsearch = true;
      breakindent = true;
    };

    plugins = {
      # nvim-ufo = {
      #   enable = true;
      # };
      # git-worktree = {
      #   enable = true;
      #   enableTelescope = true;
      # };
      ollama = {
        enable = true;
        # ssh -L 11434:0.0.0.0:11434 home_desktop -N
        url = "http://127.0.0.1:11434";
        model = "llama3";
        # model = "codestral";

        prompts = {
          mathproof = {
            prompt = ''Отвечай пользователю на русском языке'';
            model = "mistral";
            inputLabel = "> ";
          };
        };
      };

      dashboard.enable = true;
      indent-blankline.enable = true;
      jupytext.enable = true;
      marks.enable = true;
      # magma-nvim.enable = true;
      improved-search = {
        enable = true;
        keymaps = [
          {
            action = "stable_next";
            key = "n";
            mode = [
              "n"
              "x"
              "o"
            ];
          }
          {
            action = "stable_previous";
            key = "N";
            mode = [
              "n"
              "x"
              "o"
            ];
          }
          {
            action = "current_word";
            key = "!";
            mode = "n";
            options = {
              desc = "Search current word without moving";
            };
          }
          {
            action = "in_place";
            key = "!";
            mode = "x";
          }
          {
            action = "forward";
            key = "*";
            mode = "x";
          }
          {
            action = "backward";
            key = "#";
            mode = "x";
          }
          {
            action = "in_place";
            key = "|";
            mode = "n";
          }
        ];
      };
      dressing = {
        enable = true;
        settings = {
          input = {
            enabled = true;
            default_prompt = "Input";
            trim_prompt = true;
            border = "rounded";
            relative = "cursor";
            mappings = {
              i = {
                "<C-c>" = "Close";
                "<CR>" = "Confirm";
                "<Down>" = "HistoryNext";
                "<Up>" = "HistoryPrev";
              };
              n = {
                "<CR>" = "Confirm";
                "<Esc>" = "Close";
              };
            };
          };
          select = {
            backend = [
              "telescope"
              "fzf_lua"
              "fzf"
              "builtin"
              "nui"
            ];
            builtin = {
              mappings = {
                "<C-c>" = "Close";
                "<CR>" = "Confirm";
                "<Esc>" = "Close";
              };
            };
            enabled = true;
          };
        };
      };

      dap = {
        enable = true;

        signs = {
          dapBreakpoint = {
            text = "🟢"; # ● 🟩
            texthl = "DapBreakpoint";
          };
          dapBreakpointCondition = {
            text = "⚡"; # 🟦
            texthl = "DapBreakpointCondition";
          };
          dapLogPoint = {
            text = "📝"; # 🖊️ ◆ 🔵 🔴 🟣 🟡
            texthl = "DapLogPoint";
          };
          dapBreakpointRejected = {
            text = "❌"; # 🟥
            texthl = "DiagnosticError";
          };
          #               
          dapStopped = {
            text = "→"; # ▶️ ⏸️ ⏹️ ⏺️ ⏬🔽🎦📎🔗📌
            texthl = "DapStopped"; # ▶️ ⏸️ ⏯️ ⏹️ ⏺️ ⏭️ ⏮️
          };
        };
        extensions = {
          dap-go = {
            enable = true;
            dapConfigurations = [
              {
                type = "go";
                name = "Attach remote";
                mode = "remote";
                request = "attach";
              }
              # {
              #   type = "go";
              #   name = "Launch Prog";
              #   request = "launch";
              #   program = "\${workspaceFolder}/cmd/prog";
              #   # env = {
              #   #   CGO_ENABLED = 0;
              #   # };
              #   args = [
              #     "--arg0"
              #     "--arg1"
              #     "7080"
              #   ];
              #   envFile = "\${workspaceFolder}/.env";
              #   preLaunchTask = "Build prog";
              #   postDebugTask = "Stop prog";
              # }
            ];
            delve = {
              path = "dlv";
              initializeTimeoutSec = 20;
              port = "38697";
              # args = [];
              buildFlags = "";
              # buildFlags = ''-ldflags "-X 'gitthub.ru/back2nix/placebo/internal/app.Name=myapp' -tags=debug'';
            };
          };
          dap-python.enable = true;
          dap-ui = {
            enable = true;
            controls.enabled = true;
          };
          dap-virtual-text.enable = true;
        };

        adapters = {
        };
      };

      debugprint = {
        enable = true;
        # extraOptions.keymaps =
      };

      cmp-spell.enable = true;
      barbar.enable = true;
      auto-session = {
        enable = true;
        extraOptions = {
          auto_save_enabled = true;
          auto_restore_enabled = true;
        };
      };

      airline = {
        enable = true;
        settings = {
          powerline_fonts = true;
        };
      };
      alpha = {
        enable = true;
        theme = "dashboard";
        iconsEnabled = true;
      };

      bufferline = {
        enable = true;
        diagnostics = "nvim_lsp";
        numbers = "ordinal";
      };

      comment.enable = true;
      # comment-nvim.enable = true;
      commentary.enable = true;
      diffview = {
        enable = true;
        diffBinaries = true;
      };
      fugitive.enable = true;
      gitsigns = {
        enable = true;
        # settings.current_line_blame = true;
      };
      leap.enable = true;
      lsp-format.enable = true;
      markdown-preview = {
        enable = true;
        settings = {
          auto_close = true;
        };
      };

      # mini.enable = true;
      navbuddy.enable = true;
      # neorg.enable = true;
      # File tree
      # nvim-tree = {
      #   enable = true;
      #   diagnostics.enable = true;
      #   git.enable = true;
      # };
      neo-tree = {
        enable = true;
        enableDiagnostics = true;
        enableGitStatus = true;
        enableModifiedMarkers = true;
        enableRefreshOnWrite = true;
        closeIfLastWindow = true;
        popupBorderStyle = "rounded"; # Type: null or one of “NC”, “double”, “none”, “rounded”, “shadow”, “single”, “solid” or raw lua code
        buffers = {
          bindToCwd = false;
          followCurrentFile = {
            enabled = true;
            leaveDirsOpen = true;
          };
        };
        window = {
          width = 40;
          height = 15;
          autoExpandWidth = false;
          mappings = {
            "<space>" = "none";
          };
        };
      };

      nix = {
        enable = true;
      };

      notify.enable = true;
      sniprun.enable = true;
      surround.enable = true;
      hop = {
        enable = true;
        settings = {
          keys = "srtnyeiafg";
        };
      };

      telescope = {
        enable = true;
        extensions = {
          fzf-native = {
            enable = true;
            fuzzy = true;
            overrideGenericSorter = true;
            overrideFileSorter = true;
            caseMode = "smart_case";
          };
        };
        defaults = {
          # file_ignore_patterns = [".git" ".direnv" "target" "node_modules"];
          vimgrep_arguments = [
            "${pkgs.ripgrep}/bin/rg"
            "--hidden"
            "--color=never"
            "--no-heading"
            "--with-filename"
            "--line-number"
            "--column"
            "--smart-case"
          ];
          layout_strategy = "horizontal";
          layout_config.prompt_position = "top";
          sorting_strategy = "ascending";
        };
        extraOptions = {
          pickers = {
            git_files = {
              disable_devicons = true;
            };
            find_files = {
              disable_devicons = true;
            };
            buffers = {
              disable_devicons = true;
            };
            live_grep = {
              disable_devicons = true;
            };
            current_buffer_fuzzy_find = {
              disable_devicons = true;
            };
            lsp_definitions = {
              disable_devicons = true;
            };
            lsp_references = {
              disable_devicons = true;
            };
            diagnostics = {
              disable_devicons = true;
            };
            lsp_dynamic_workspace_symbols = {
              disable_devicons = true;
            };
          };
        };
        keymaps = {
          # "<leader>f" = "git_files";
          # "<leader>F" = "find_files";
          # "gb" = "buffers";
          # "<leader><space>" = "live_grep";
          # "<leader>/" = "current_buffer_fuzzy_find";
          # "gd" = "lsp_definitions";
          "gI" = "lsp_incoming_calls";
          # "gi" = "lsp_implementations";
          # "gt" = "lsp_type_definition";
          "<leader>fd" = "diagnostics";
          "<leader>s" = "lsp_dynamic_workspace_symbols";
        };
      };

      yanky = {
        enable = true;
        picker.telescope = {
          enable = true;
        };
      };

      todo-comments = {
        enable = true;
        colors = {
          error = ["DiagnosticError" "ErrorMsg" "#DC2626"];
          warning = ["DiagnosticWarn" "WarningMsg" "#FBBF24"];
          info = ["DiagnosticInfo" "#2563EB"];
          hint = ["DiagnosticHint" "#10B981"];
          default = ["Identifier" "#7C3AED"];
          test = ["Identifier" "#FF00FF"];
        };
      };

      floaterm.enable = true;
      # https://github.com/jackyliu16/home-manager/blob/f792c1c57e240d24064850c6221719ad758c6c6b/vimAndNeovim/nixvim.nix#L97
      treesitter = {
        enable = true;
        indent = true;
        ensureInstalled = [
          "rust"
          "python"
          "c"
          "cpp"
          "toml"
          "nix"
          "go"
          "gomod"
          "gotmpl"
          "gosum"
          "gowork"
          "java"
        ];
        grammarPackages = with config.plugins.treesitter.package.builtGrammars; [
          c
          go
          gomod
          gosum
          gowork
          gotmpl
          cpp
          nix
          bash
          html
          # help
          latex
          python
          rust
        ];
      };
      treesitter-context.enable = true;
      trouble.enable = true;
      which-key = {
        enable = true;
        plugins.spelling.enabled = false;
        triggersNoWait = ["`" "'" "<leader>" "g`" "g'" "\"" "<c-r>" "z=" "<Space>"];
        disable = {
          buftypes = [];
          filetypes = [];
        };
        triggersBlackList = {
          i = ["j" "k"];
          v = ["j" "k"];
        };
      };
      # multicursors.enable = true;
      # ERROR: [Hydra.nvim] Option "hint.border" has been deprecated and will be removed on 2024-02-01 -- See hint.float_opts
      lastplace.enable = true;

      none-ls = {
        tempDir = "/tmp";
        enable = true;
        enableLspFormat = true;
        updateInInsert = false;
        sources = {
          code_actions = {
            gitsigns.enable = true;
            statix.enable = true;
            gomodifytags.enable = true;
            impl.enable = true;
          };
          diagnostics = {
            statix.enable = true;
            yamllint.enable = true;
            codespell.enable = true;
          };
          formatting = {
            golines = {
              enable = true;
              withArgs = ''
                {
                  extra_args = { "--no-reformat-tags", "--max-len=128" },
                }
              '';
            };
            gofumpt.enable = true;
            # goimports.enable = true;
            goimports_reviser.enable = true;

            sqlformat.enable = true;

            # Nix
            alejandra.enable = true;

            # Python
            blackd.enable = true;

            black = {
              enable = true;
              withArgs = ''
                {
                  extra_args = { "--fast" },
                }
              '';
            };

            # JS
            # prettier = {
            #   enable = true;
            #   disableTsServerFormatter = true;
            #   withArgs = ''
            #     {
            #       extra_args = { "--single-quote" },
            #     }
            #   '';
            # };
            stylua.enable = true;
            # yamlfmt.enable = true;
          };
        };
      };

      # Language server
      lsp = {
        enable = true;

        servers = {
          # Average webdev LSPs
          golangci-lint-ls.enable = true;
          gopls = {
            enable = true;
            autostart = true;
            onAttach.function = ''
              if not client.server_capabilities.semanticTokensProvider then
              local semantic = client.config.capabilities.textDocument.semanticTokens
              client.server_capabilities.semanticTokensProvider = {
                full = true,
                legend = {
                  tokenTypes = semantic.tokenTypes,
                  tokenModifiers = semantic.tokenModifiers,
                },
                range = true,
              }
              end
            '';
            extraOptions = {
              settings = {
                gopls = {
                  gofumpt = true;
                  codelenses = {
                    gc_details = false;
                    generate = true;
                    regenerate_cgo = true;
                    run_govulncheck = true;
                    test = true;
                    tidy = true;
                    upgrade_dependency = true;
                    vendor = true;
                  };
                  hints = {
                    assignVariableTypes = true;
                    compositeLiteralFields = true;
                    compositeLiteralTypes = true;
                    constantValues = true;
                    functionTypeParameters = true;
                    parameterNames = true;
                    rangeVariableTypes = true;
                  };
                  analyses = {
                    fieldalignment = true;
                    nilness = true;
                    unusedparams = true;
                    unusedwrite = true;
                    unusedvariable = true;
                    fillreturns = true;
                    fillswitch = true;
                    undeclared = true;
                    useany = true;
                    embeddirective = true;
                    deprecated = true;
                    fillstruct = true;
                  };
                  usePlaceholders = true;
                  completeUnimported = true;
                  staticcheck = true;
                  directoryFilters = ["-.git" "-.vscode" "-.idea" "-.vscode-test" "-node_modules"];
                  semanticTokens = true;
                };
              };
            };
          };
          nil_ls.enable = true;
          svelte.enable = false; # Svelte
          vuels.enable = false; # Vue
          tsserver.enable = true; # TS/JS
          cssls.enable = true; # CSS
          tailwindcss.enable = true; # TailwindCSS
          html.enable = true; # HTML
          astro.enable = true; # AstroJS
          # phpactor.enable = true; # PHP
          jsonls.enable = true;

          # Python
          pyright.enable = true;
          # Markdown
          marksman.enable = true;
          # Nix
          nil-ls.enable = true;
          # Docker
          dockerls.enable = true;
          # Bash
          bashls.enable = true;
          # C/C++
          clangd.enable = true;
          # C#
          csharp-ls.enable = true;
          # Lua
          lua-ls = {
            enable = true;
            settings.telemetry.enable = false;
          };
          # Rust
          # rust-analyzer = {
          #   enable = true;
          #   installRustc = true;
          #   installCargo = true;
          # };
        };
      };

      # luasnip.enable = true;
      cmp = {
        enable = true;

        settings = {
          snippet.expand = "function(args) require('luasnip').lsp_expand(args.body) end";

          mapping = {
            "<C-Space>" = "cmp.mapping.complete()";
            "<CR>" = "cmp.mapping.confirm()";
            "<ESC>" = "cmp.mapping.close()";
            "<Down>" = "cmp.mapping.select_next_item()";
            "<C-j>" = "cmp.mapping.select_next_item()";
            "<Tab>" = "cmp.mapping.select_next_item()";
            "<Up>" = "cmp.mapping.select_prev_item()";
            "<C-k>" = "cmp.mapping.select_prev_item()";
            "<S-Tab>" = "cmp.mapping.select_prev_item()";
          };

          sources = [
            {name = "path";}
            {name = "nvim_lsp";}
            {name = "cmp_tabby";}
            {name = "luasnip";}
            {
              name = "buffer";
              option.get_bufnrs.__raw = "vim.api.nvim_list_bufs";
            }
            {name = "neorg";}
            {name = "nvim_lsp_signature_help";}
            {name = "treesitter";}
            {name = "dap";}
          ];
        };
      };

      lspkind = {
        enable = true;

        cmp = {
          enable = true;
          menu = {
            nvim_lsp = "[LSP]";
            nvim_lua = "[api]";
            path = "[path]";
            luasnip = "[snip]";
            buffer = "[buffer]";
            dap = "[dap]";
            treesitter = "[treesitter]";
            # neorg = "[neorg]";
            cmp_tabby = "[Tabby]";
          };
        };
      };

      # Dashboard
      # cmp.enable = true;
      cmp-treesitter.enable = true;
      cmp-nvim-lsp.enable = true;
      cmp-path.enable = true;
      cmp-rg.enable = true;
      cmp-nvim-lua.enable = true;
      cmp-dap.enable = true;
      cmp-buffer.enable = true;
      cmp_luasnip.enable = true;
      cmp-cmdline.enable = false;
      cmp-nvim-lsp-signature-help.enable = true;
      # cmp-tabby.host = "http://127.0.0.1:8080";
      # vim-lspconfig.enable = true;
      nvim-cmp = {
        enable = true;
      };
      conform-nvim = {
        enable = true;

        formattersByFt = {
          "*" = ["codespell"];
          "_" = ["trim_whitespace"];
          go = [
            # "goimports"
            "goimports_reviser"
            # "golines"
            # "gofmt"
            "gofumpt"
          ];
          javascript = [["prettierd" "prettier"]];
          json = ["jq"];
          lua = ["stylua"];
          nix = ["alejandra"];
          python = ["isort" "black"];
          rust = ["rustfmt"];
          sh = ["shfmt"];
          terraform = ["terraform_fmt"];
        };

        formatOnSave = ''
          function(bufnr)
          local ignore_filetypes = { "helm" }
          if vim.tbl_contains(ignore_filetypes, vim.bo[bufnr].filetype) then
          return
          end

          -- Disable with a global or buffer-local variable
          if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
          return
          end

          -- Disable autoformat for files in a certain path
          local bufname = vim.api.nvim_buf_get_name(bufnr)
          if bufname:match("/node_modules/") then
          return
          end
          return { timeout_ms = 1000, lsp_fallback = true }
          end
        '';
      };
    };
    luaLoader.enable = true;
  };
}
