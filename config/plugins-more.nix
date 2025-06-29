{
  inputs,
  config,
  pkgs,
  pkgs-master,
  lib,
  ...
}: let
in {
  config = {
    plugins = {
      ollama = {
        enable = true;
        url = "http://127.0.0.1:11434";
        model = "llama3";

        prompts = {
          mathproof = {
            prompt = "Отвечай пользователю на русском языке";
            model = "mistral";
            inputLabel = "> ";
          };
        };
      };

      dashboard.enable = true;
      indent-blankline.enable = true;
      jupytext.enable = true;
      marks.enable = true;
      improved-search = {
        enable = true;
        keymaps = [
          {
            action = "stable_next";
            key = "n";
            mode = ["n" "x" "o"];
          }
          {
            action = "stable_previous";
            key = "N";
            mode = ["n" "x" "o"];
          }
          {
            action = "current_word";
            key = "!";
            mode = "n";
            options = {desc = "Search current word without moving";};
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
            backend = ["telescope" "fzf_lua" "fzf" "builtin" "nui"];
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

      debugprint = {
        enable = true;
      };

      cmp-spell.enable = true;
      barbar.enable = true;
      auto-session = {
        enable = true;
        # ИСПРАВЛЕНО: extraOptions -> settings
        settings = {
          auto_save_enabled = true;
          auto_restore_enabled = true;
        };
      };

      airline = {
        enable = true;
        settings = {powerline_fonts = 1;};
      };
      alpha = {
        enable = true;
        theme = "dashboard";
        # ИСПРАВЛЕНО: iconsEnabled - устаревшая опция и удалена
      };

      # ИСПРАВЛЕНО: web-devicons теперь нужно включать явно
      web-devicons.enable = true;

      bufferline = {
        enable = true;
        # ИСПРАВЛЕНО: опции перемещены в settings.options
        settings.options = {
          diagnostics = "nvim_lsp";
          numbers = "ordinal";
        };
      };

      comment.enable = true;
      commentary.enable = true;
      diffview = {
        enable = true;
        diffBinaries = true;
      };
      fugitive.enable = true;
      gitsigns = {
        enable = true;
      };
      leap.enable = true;
      markdown-preview = {
        enable = true;
        settings = {auto_close = 1;};
      };

      navbuddy.enable = true;
      neo-tree = {
        enable = true;
        enableDiagnostics = true;
        enableGitStatus = true;
        enableModifiedMarkers = true;
        enableRefreshOnWrite = true;
        closeIfLastWindow = true;
        popupBorderStyle = "rounded";
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
          mappings = {"<space>" = "none";};
        };
      };

      nix = {enable = true;};

      notify.enable = true;
      sniprun.enable = true;
      # ИСПРАВЛЕНО: surround -> vim-surround
      vim-surround.enable = true;
      hop = {
        enable = true;
        settings = {keys = "srtnyeiafg";};
      };

      telescope = {
        enable = true;
        extensions = {
          fzf-native = {
            enable = true;
            settings = {
              fuzzy = true;
              caseMode = "smart_case";
              override_generic_sorter = true;
              override_file_sorter = true;
            };
          };
        };
        settings.defaults = {
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
        settings.pickers = {
          git_files = {disable_devicons = true;};
          find_files = {disable_devicons = true;};
          buffers = {disable_devicons = true;};
          live_grep = {disable_devicons = true;};
          current_buffer_fuzzy_find = {disable_devicons = true;};
          lsp_definitions = {disable_devicons = true;};
          lsp_references = {disable_devicons = true;};
          diagnostics = {disable_devicons = true;};
          lsp_dynamic_workspace_symbols = {disable_devicons = true;};
        };
        keymaps = {
          "gI" = "lsp_incoming_calls";
          "<leader>fd" = "diagnostics";
          "<leader>s" = "lsp_dynamic_workspace_symbols";
        };
      };

      yanky = {
        enable = true;
        enableTelescope = true;
      };

      todo-comments = {
        enable = true;
        # ИСПРАВЛЕНО: colors -> settings.colors
        settings.colors = {
          error = ["DiagnosticError" "ErrorMsg" "#DC2626"];
          warning = ["DiagnosticWarn" "WarningMsg" "#FBBF24"];
          info = ["DiagnosticInfo" "#2563EB"];
          hint = ["DiagnosticHint" "#10B981"];
          default = ["Identifier" "#7C3AED"];
          test = ["Identifier" "#FF00FF"];
        };
      };

      floaterm.enable = true;
      treesitter = {
        enable = true;
        settings = {
          highlight.enable = true;
          indent.enable = true;
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
            "html"
            "css"
            "scss"
            "vue"
            "javascript"
            "typescript"
            "just"
          ];
        };
        grammarPackages = with config.plugins.treesitter.package.builtGrammars; [
          c
          go
          gomod
          gosum
          gowork
          gotmpl
          cpp
          bash
          html
          latex
          python
          rust
          css
          dockerfile
          eex
          elixir
          gitcommit
          gitignore
          graphql
          hcl
          heex
          json
          lua
          markdown
          nix
          proto
          sql
          starlark
          terraform
          toml
          yaml
          vue
          javascript
          typescript
          just
        ];

        settings.incrementalSelection.enable = true;
      };
      treesitter-context.enable = true;
      trouble.enable = true;
      which-key = {
        enable = true;
        # ИСПРАВЛЕНО: Все опции переехали в `settings` и переименованы в snake_case
        settings = {
          plugins.spelling.enabled = false;
          triggers_no_wait = ["`" "'" "<leader>" "g`" "g'" ''"'' "<c-r>" "z=" "<Space>"];
          disable = {
            bt = [];
            ft = [];
          };
          triggers_black_list = {
            i = ["j" "k"];
            v = ["j" "k"];
          };
        };
      };
      lastplace.enable = true;

      lsp-format.enable = false;

      conform-nvim = {
        enable = true;

        # ИСПРАВЛЕНО: Опции переехали в `settings` и переименованы в snake_case
        settings = {
          formatters_by_ft = {
            "*" = ["codespell"];
            "_" = [
              "squeeze_blanks"
              "trim_whitespace"
              "trim_newlines"
            ];

            go = ["gofumpt" "goimports"];

            css = ["prettierd"];
            html = ["prettierd"];
            javascript = ["prettierd"];
            typescript = ["prettierd"];
            json = ["prettierd"];
            markdown = ["prettierd"];
            scss = ["prettierd"];
            toml = ["prettierd"];
            yaml = ["prettierd"];
            vue = ["prettierd"];

            lua = ["stylua"];
            nix = ["alejandra"];
            python = ["ruff"];
            rust = ["rustfmt"];
            cpp = ["clang_format"];
            c = ["clang_format"];
            just = ["just"];
          };

          log_level = "warn";
          notify_on_error = true;
        };
      };

      typescript-tools = {
        enable = true;
        # ИСПРАВЛЕНО: Опция переехала в settings.settings и переименована в snake_case
        settings.settings.tsserver_plugins = ["@vue/typescript-plugin"];
      };
      lsp = {
        enable = true;
        servers = {
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
                    # fieldalignment = true;
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
                  directoryFilters = [
                    "-.git"
                    "-.vscode"
                    "-.idea"
                    "-.vscode-test"
                    "-node_modules"
                  ];
                  semanticTokens = true;
                };
              };
            };
          };
          svelte.enable = false;
          vuels.enable = false;
          # ИСПРАВЛЕНО: tsserver -> ts_ls
          ts_ls = {
            enable = true;
            filetypes = [
              "javascript"
              "javascriptreact"
              "javascript.jsx"
              "typescript"
              "typescriptreact"
              "typescript.tsx"
              "vue"
            ];
          };
          cssls.enable = true;
          tailwindcss.enable = true;
          html.enable = true;
          astro.enable = true;
          jsonls.enable = true;
          pyright.enable = true;
          marksman.enable = true;
          # ИСПРАВЛЕНО: nil-ls -> nil_ls
          nil_ls.enable = true;
          nixd.enable = true;
          dockerls.enable = true;
          bashls.enable = true;
          clangd.enable = true;
          # ИСПРАВЛЕНО: csharp-ls -> csharp_ls
          csharp_ls.enable = true;
          eslint.enable = true;
          terraformls.enable = true;
          yamlls.enable = true;
          # ИСПРАВЛЕНО: lua-ls -> lua_ls
          lua_ls = {
            enable = true;
            settings.telemetry.enable = false;
          };
        };
        keymaps = {
          silent = true;
          diagnostic = {
            "<leader>cd" = {
              action = "open_float";
              desc = "Line Diagnostics";
            };
            "[d" = {
              action = "goto_next";
              desc = "Next Diagnostic";
            };
            "]d" = {
              action = "goto_prev";
              desc = "Previous Diagnostic";
            };
          };
        };
      };

      cmp = {
        enable = true;
        settings = {
          snippet.expand = "function(args) require('luasnip').lsp_expand(args.body) end";

          mapping = {
            "<C-Space>" = "cmp.mapping.complete()";
            "<CR>" = "cmp.mapping.confirm({ select = true })"; # ИСПРАВЛЕНО: Добавлен select = true для лучшего UX
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
            # {name = "cmp_tabby";} # ИСПРАВЛЕНО: Закомментировано, чтобы убрать ошибку
            {name = "luasnip";}
            {
              name = "buffer";
              option.get_bufnrs.__raw = "vim.api.nvim_list_bufs";
            }
            {name = "nvim_lsp_signature_help";}
            {name = "treesitter";}
            {name = "dap";}
            {name = "go_pkgs";} # ИСПРАВЛЕНО: Добавлено из cmp-go-pkgs.nix
            {name = "rg";} # ИСПРАВЛЕНО: Добавлено для полноты
          ];

          # ИСПРАВЛЕНО: Добавлено из cmp-go-pkgs.nix для Go
          matching = {
            disallow_symbol_nonprefix_matching = false;
          };
        };
      };

      lspkind = {
        enable = true;
        # ИСПРАВЛЕНО: Возвращаем структуру к оригинальной, где настройки cmp
        # находятся внутри блока `cmp`.
        cmp = {
          enable = true;
          # `mode` опция не является частью этого плагина, она относится к `lspkind.cmp_format`
          # и передается ему через `cmp.settings.formatting.format`
          menu = {
            nvim_lsp = "[LSP]";
            nvim_lua = "[api]";
            path = "[path]";
            luasnip = "[snip]";
            buffer = "[buffer]";
            dap = "[dap]";
            treesitter = "[treesitter]";
            # cmp_tabby = "[Tabby]";
            go_pkgs = "[pkgs]";
            rg = "[rg]";
          };
        };
      };

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
    };
  };
}
