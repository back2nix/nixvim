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
    # ./highlight.nix
    # ./plug/colorscheme/biscuit.nix
    # ./plug/colorscheme/colorscheme.nix
    ./autocommands.nix
    ./plugins/persistent-breakpoints.nvim.nix
    ./plugins/git-blame.nvim.nix
    ./plugins/buffer.nix
    ./plugins/oil.nix
    ./plugins/git-worktree.nix
    ./plugins/spell.nix
    # ./plug/ui/btw.nix
    ./plug/ui/telescope.nix
    ./plug/utils/undotree.nix
    ./plug/ui/nvim-notify.nix
    # ./theme.nix
    # inputs.nixvim.homeManagerModules.nixvim
    # ./plugins/lspsaga.nix
    # ./plugins/bash
    # ./plugins/dap.nix
    # ./plugins/colorscheme.nix
  ];

  options = {
  };
  config = {
    # colorschemes.gruvbox.enable = true;
    # colorschemes.dracula.enable = true;
    colorschemes.nightfox.enable = true;

    # clipboard = {
    #   register = "unnamedplus";
    #   # TODO: Make conditional if X11/Wayland enabled
    #   # providers.wl-copy.enable = true;
    #   providers.xclip.enable = pkgs.stdenv.isLinux;
    #   providers.xsel.enable = pkgs.stdenv.isDarwin;
    # };

    extraConfigLua = ''
      vim.api.nvim_create_user_command("Pwd", 'let @+=expand("%:p") | echo expand("%:p")', {})

      local function myRepl(t)
        if t.range ~= 0 then
          vim.cmd "'<,'>s/null/nil/ge | '<,'>s/\\[/\\{/ge | '<,'>s/\\]/\\}/ge"
        else
          vim.cmd "%s/null/nil/ge | %s/\\[/\\{/ge | %s/\\]/\\}/ge"
        end
      end
      vim.api.nvim_create_user_command("MyRepl", function(t) myRepl(t) end, { range = true })

      local function myReplQu(t)
        if t.range ~= 0 then
          vim.cmd "'<,'>s/\"/'/ge"
        else
          vim.cmd "%s/\"/'/ge"
        end
      end
      vim.api.nvim_create_user_command("MyReplQu", function(t) myReplQu(t) end, { range = true })

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
      #comment-nvim.enable = true;
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

      luasnip.enable = true;
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

    keymaps = [
      {
        key = "<C-Space>";
        action = "lua require('cmp').mapping.complete()";
        options = {
          desc = "Invoke autocomplete menu";
          silent = true;
        };
      }
      {
        key = "<C-e>";
        action = "lua require('cmp').mapping.close()";
        options = {
          desc = "Close autocomplete menu";
          silent = true;
        };
      }
      {
        key = "<CR>";
        action = "lua require('cmp').mapping.confirm({ select = true })";
        options = {
          desc = "Confirm autocomplete selection";
          silent = true;
        };
      }
      # astronvim keymaps from chat-gpt4
      {
        action = ":HopWord<CR>";
        options = {
          desc = "Jump by letters";
          silent = true;
        };
        key = "s";
      }
      {
        action = ":HopLine<CR>";
        options = {
          desc = "Jump by letters";
          silent = true;
        };
        key = "S";
      }
      # General Mappings
      {
        key = "<C-Up>";
        action = ":resize +2<CR>";
        options = {
          desc = "Increase window size upwards";
          silent = true;
        };
      }
      {
        key = "<C-Down>";
        action = ":resize -2<CR>";
        options = {
          desc = "Decrease window size downwards";
          silent = true;
        };
      }
      {
        key = "<C-Left>";
        action = ":vertical resize -2<CR>";
        options = {
          desc = "Decrease window size to the left";
          silent = true;
        };
      }
      {
        key = "<C-Right>";
        action = ":vertical resize +2<CR>";
        options = {
          desc = "Increase window size to the right";
          silent = true;
        };
      }
      {
        key = "<C-k>";
        action = "<C-w>k";
        options = {
          desc = "Move to the window above";
          silent = true;
        };
      }
      {
        key = "<C-j>";
        action = "<C-w>j";
        options = {
          desc = "Move to the window below";
          silent = true;
        };
      }
      {
        key = "<C-h>";
        action = "<C-w>h";
        options = {
          desc = "Move to the window on the left";
          silent = true;
        };
      }
      {
        key = "<C-l>";
        action = "<C-w>l";
        options = {
          desc = "Move to the window on the right";
          silent = true;
        };
      }
      {
        key = "<C-s>";
        action = ":w!<CR>";
        options = {
          desc = "Force save";
          silent = true;
        };
      }
      # {
      #   key = "<C-q>";
      #   action = ":q!<CR>";
      #   options = { desc = "Force close";  silent = true; };
      # }
      {
        key = "<leader>n";
        action = ":new<CR>";
        options = {
          desc = "Create a new file";
          silent = true;
        };
      }
      {
        key = "<leader>c";
        action = "<cmd>lua buffer_close()<cr>";
        options = {
          desc = "Close buffer";
          silent = true;
        };
      }
      {
        key = "<leader>C";
        action = "<cmd>lua buffer_close(0, true)<cr>";
        options = {
          desc = "Force close buffer";
          silent = true;
        };
      }
      {
        key = "]t";
        action = ":tabnext<CR>";
        options = {
          desc = "Next tab";
          silent = true;
        };
      }
      {
        key = "[t";
        action = ":tabprevious<CR>";
        options = {
          desc = "Previous tab";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>/";
        action = "gcc";
        options.remap = true;
        options = {
          desc = "Comment line";
          silent = true;
        };
      }
      {
        mode = "v";
        key = "<leader>/";
        action = "gc";
        options.remap = true;
        options = {
          desc = "Comment";
          silent = true;
        };
      }
      {
        key = "\\";
        action = ":split<CR>";
        options = {
          desc = "Horizontal split";
          silent = true;
        };
      }
      {
        key = "|";
        action = ":vsplit<CR>";
        options = {
          desc = "Vertical split";
          silent = true;
        };
      }
      # Buffers
      {
        mode = ["n" "v"];
        key = "<leader>b";
        action = "+buffers";
        options = {desc = "📄 Buffers";};
      }
      {
        key = "]b";
        action = ":bnext<CR>";
        options = {
          desc = "Next buffer";
          silent = true;
        };
      }
      {
        key = "[b";
        action = ":bprevious<CR>";
        options = {
          desc = "Previous buffer";
          silent = true;
        };
      }
      {
        key = "<leader>bb";
        action = ":Telescope buffers<CR>";
        options = {
          desc = "Switch to buffer using interactive selection";
          silent = true;
        };
      }
      {
        key = "<leader>bc";
        action = "<cmd>lua buffer_close_all(true)<cr>";
        options = {
          desc = "Close all buffers, кроме текущего";
          silent = true;
        };
      }
      {
        key = "<leader>bC";
        action = ":BufferCloseAll<CR>";
        options = {
          desc = "Close all buffers";
          silent = true;
        };
      }
      {
        key = "<leader>bd";
        action = "<cmd>lua buffer_close_all()<cr>";
        options = {
          desc = "Delete buffer using interactive selection";
          silent = true;
        };
      }
      {
        key = "<leader>bl";
        action = ":BufferCloseBuffersLeft<CR>";
        options = {
          desc = "Close all buffers to the left of the current one";
          silent = true;
        };
      }
      {
        key = "<leader>bp";
        action = ":bprevious<CR>";
        options = {
          desc = "Switch to the previous buffer";
          silent = true;
        };
      }
      {
        key = "<leader>br";
        action = ":BufferCloseBuffersRight<CR>";
        options = {
          desc = "Close all buffers to the right of the current one";
          silent = true;
        };
      }
      {
        key = "<leader>bse";
        action = ":BufferOrderByExtension<CR>";
        options = {
          desc = "Sort buffers by extension";
          silent = true;
        };
      }
      {
        key = "<leader>bsi";
        action = ":BufferOrderByBufferNumber<CR>";
        options = {
          desc = "Sort buffers by number";
          silent = true;
        };
      }
      {
        key = "<leader>bsm";
        action = ":BufferOrderByLastModification<CR>";
        options = {
          desc = "Sort buffers by last modification";
          silent = true;
        };
      }
      {
        key = "<leader>bsp";
        action = ":BufferOrderByFullPath<CR>";
        options = {
          desc = "Sort buffers by full path";
          silent = true;
        };
      }
      {
        key = "<leader>bsr";
        action = ":BufferOrderByRelativePath<CR>";
        options = {
          desc = "Sort buffers by relative path";
          silent = true;
        };
      }
      {
        key = "<leader>b\\";
        action = ":split | Telescope buffers<CR>";
        options = {
          desc = "Open buffer in new horizontal split using interactive selection";
          silent = true;
        };
      }
      {
        key = "<leader>b|";
        action = ":vsplit | Telescope buffers<CR>";
        options = {
          desc = "Open buffer in new vertical split using interactive selection";
          silent = true;
        };
      }
      # Completion
      {
        key = "<C-Space>";
        action = ":lua vim.fn.complete(vim.fn.col('.'), vim.fn['compe#complete']())<CR>";
        options = {
          desc = "Open autocomplete menu";
          silent = true;
        };
      }
      {
        key = "<CR>";
        action = ":lua vim.fn['compe#confirm']('<CR>')<CR>";
        options = {
          desc = "Select autocomplete";
          silent = true;
        };
      }
      {
        key = "<Tab>";
        action = ":lua vim.fn  ? '<Plug>(vsnip-jump-next)' : '<Tab>'<CR>";
        options = {
          desc = "Next snippet position";
          silent = true;
        };
      }
      {
        key = "<S-Tab>";
        action = ":lua vim.fn['vsnip#jumpable'](-1) ? '<Plug>(vsnip-jump-prev)' : '<S-Tab>'<CR>";
        options = {
          desc = "Previous snippet position";
          silent = true;
        };
      }
      # {
      #   key = "<Down>";
      #   action = ":lua vim.fn['compe#scroll']({ 'delta': +4 })<CR>";
      #   options = {
      #     desc = "Next autocomplete (down)";
      #     silent = true;
      #   };
      # }
      {
        key = "<C-n>";
        action = ":lua vim.fn['compe#scroll']({ 'delta': +4 })<CR>";
        options = {
          desc = "Next autocomplete (down)";
          silent = true;
        };
      }
      {
        key = "<C-j>";
        action = ":lua vim.fn['compe#scroll']({ 'delta': +4 })<CR>";
        options = {
          desc = "Next autocomplete (down)";
          silent = true;
        };
      }
      # Neo-Tree
      {
        key = "<leader>e";
        action = ":Neotree toggle<CR>";
        options = {
          desc = "Toggle Neotree";
          silent = true;
        };
      }
      {
        key = "<leader>oo";
        action = ":Ollama<CR>";
        options = {
          desc = "Ollama";
          silent = true;
        };
      }
      # Session Manager Mappings
      {
        mode = ["n" "v"];
        key = "<leader>S";
        action = "+Session";
        options = {desc = "📄 Session";};
      }
      {
        key = "<leader>Ss";
        action = ":SessionSave<CR>";
        options = {
          desc = "Save session";
          silent = true;
        };
      }
      {
        key = "<leader>Sr";
        action = ":SessionRestore<CR>";
        options = {
          desc = "Restore session";
          silent = true;
        };
      }
      {
        key = "gt";
        action.__raw = ''function() require("telescope.builtin").lsp_type_definitions { reuse_win = true } end'';
        options = {
          desc = "Go to type definition";
          silent = true;
        };
      }
      {
        key = "gd";
        action.__raw = ''function() require("telescope.builtin").lsp_definitions { reuse_win = true } end'';
        options = {
          desc = "Go to definition";
          silent = true;
        };
      }
      {
        key = "gi";
        action.__raw = ''function() require("telescope.builtin").lsp_implementations { reuse_win = true } end'';
        options = {
          desc = "Go to implementation";
          silent = true;
        };
      }
      {
        key = "gr";
        action.__raw = ''function() require("telescope.builtin").lsp_references() end'';
        options = {
          desc = "Find references";
          silent = true;
        };
      }
      {
        key = "<leader>li";
        action = ":LspInfo<CR>";
        options = {
          desc = "LSP info";
          silent = true;
        };
      }
      {
        key = "K";
        action = ":lua vim.lsp.buf.hover()<CR>";
        options = {
          desc = "Show hover";
          silent = true;
        };
      }
      {
        key = "<leader>ga";
        action = ":lua vim.lsp.buf.code_action()<CR>";
        options = {
          desc = "code action";
          silent = true;
        };
      }
      {
        key = "<leader>gh";
        action = ":lua vim.lsp.buf.signature_help()<CR>";
        options = {
          desc = "Signature help";
          silent = true;
        };
      }
      {
        key = "gn";
        action = "<CMD>lua vim.lsp.buf.rename()<CR>";
        options = {
          desc = "Rename symbol";
          silent = true;
        };
      }
      {
        key = "<leader>lr";
        action = "<CMD>lua vim.lsp.buf.rename()<CR>";
        options = {
          desc = "Rename symbol";
          silent = true;
        };
      }
      {
        key = "<leader>ls";
        action = ":lua vim.lsp.buf.document_symbol()<CR>";
        options = {
          desc = "Show document symbols";
          silent = true;
        };
      }
      {
        key = "<leader>lG";
        action = "workspace_symbol";
        options = {
          desc = "Show workspace symbols";
          silent = true;
        };
      }
      {
        key = "]d";
        action = ":lua vim.diagnostic.goto_next()<CR>";
        options = {
          desc = "Go to next diagnostic";
          silent = true;
        };
      }
      {
        key = "[d";
        action = ":lua vim.diagnostic.goto_prev()<CR>";
        options = {
          desc = "Go to previous diagnostic";
          silent = true;
        };
      }
      # Debugger Mappings
      {
        mode = ["n" "v"];
        key = "<leader>d";
        action = "+debug";
        options = {
          desc = "🛠️ Debug";
          silent = true;
        };
      }
      {
        key = "<leader>dc";
        action = ":lua require('dap').continue()<CR>";
        options = {
          desc = "Start/continue debug";
          silent = true;
        };
      }
      {
        key = "<F5>";
        action = ":lua require('dap').continue()<CR>";
        options = {
          desc = "Start/continue debug";
          silent = true;
        };
      }
      {
        mode = ["n" "v"];
        key = "<Leader>dP";
        # action = "function() require('dap.ui.widgets').preview() end";
        action = ":lua require('dap.ui.widgets').preview()<CR>";
        options = {
          desc = "Preview";
          silent = true;
        };
      }
      {
        key = "<leader>dp";
        # action = ":lua require('dap').pause()<CR>";
        action = ":lua require('dap').set_breakpoint(nil, nil, vim.fn.input('Log point message: '))<CR>";
        options = {
          # desc = "Pause debug";
          desc = "DapLogPoint";
          silent = true;
        };
      }
      {
        key = "<F6>";
        action = ":lua require('dap').pause()<CR>";
        options = {
          desc = "Pause debug";
          silent = true;
        };
      }
      {
        key = "<leader>dr";
        action = ":lua require('dap').restart()<CR>";
        options = {
          desc = "Restart debug";
          silent = true;
        };
      }
      {
        key = "<C-F5>";
        action = ":lua require('dap').restart()<CR>";
        options = {
          desc = "Restart debug";
          silent = true;
        };
      }
      {
        key = "<leader>ds";
        action = ":lua require('dap').run_to_cursor()<CR>";
        options = {
          desc = "Run to cursor";
          silent = true;
        };
      }
      {
        key = "<leader>dq";
        action = ":lua require('dap').close()<CR>";
        options = {
          desc = "Close debug";
          silent = true;
        };
      }
      {
        key = "<leader>dQ";
        action = ":lua require('dap').terminate()<CR>";
        options = {
          desc = "Terminate debug";
          silent = true;
        };
      }
      {
        key = "<S-F5>";
        action = ":lua require('dap').terminate()<CR>";
        options = {
          desc = "Terminate debug";
          silent = true;
        };
      }
      {
        key = "<F9>";
        action = ":lua require('dap').toggle_breakpoint()<CR>";
        options = {
          desc = "Toggle breakpoint";
          silent = true;
        };
      }
      {
        key = "<S-F9>";
        action = ":lua require('dap').set_breakpoint(vim.fn.input('Breakpoint condition: '))<CR>";
        options = {
          desc = "Set conditional breakpoint";
          silent = true;
        };
      }
      # {
      #   key = "<leader>dB";
      #   action = ":lua require('dap').clear_breakpoints()<CR>";
      #   options = { desc = "Clear breakpoints"; silent = true; };
      # }
      {
        key = "<leader>do";
        action = ":lua require('dap').step_over()<CR>";
        options = {
          desc = "Step over";
          silent = true;
        };
      }
      {
        key = "<F10>";
        action = ":lua require('dap').step_over()<CR>";
        options = {
          desc = "Step over";
          silent = true;
        };
      }
      {
        key = "<leader>di";
        action = ":lua require('dap').step_into()<CR>";
        options = {
          desc = "Step into";
          silent = true;
        };
      }
      {
        key = "<F11>";
        action = ":lua require('dap').step_into()<CR>";
        options = {
          desc = "Step into";
          silent = true;
        };
      }
      {
        key = "<leader>dO";
        action = ":lua require('dap').step_out()<CR>";
        options = {
          desc = "Step out";
          silent = true;
        };
      }
      {
        key = "<S-F11>";
        action = ":lua require('dap').step_out()<CR>";
        options = {
          desc = "Step out";
          silent = true;
        };
      }
      # {
      #   key = "<leader>dE";
      #   action = ":lua require('dap.ui).widgets'.hover()<CR>";
      #   options = { desc = "Evaluate expression"; silent = true; };
      # }
      {
        key = "<leader>dR";
        action = ":lua require('dap').repl.toggle()<CR>";
        options = {
          desc = "Toggle REPL";
          silent = true;
        };
      }
      {
        key = "<leader>du";
        action = ":lua require'dapui'.toggle()<CR>";
        options = {
          desc = "Toggle debugger UI";
          silent = true;
        };
      }
      {
        key = "<leader>dh";
        action = ":lua require'dap.ui.widgets'.hover()<CR>";
        options = {
          desc = "Debugger hint";
          silent = true;
        };
      }
      # Telescope Mappings
      {
        key = "<leader>f";
        action = "+find";
        options = {
          desc = "Telescope/Find";
          silent = true;
        };
      }
      {
        key = "<leader>fy";
        action = "<cmd>Telescope yank_history<cr>";
        options = {
          desc = "Yank history";
          silent = true;
        };
      }
      {
        key = "<leader><CR>";
        action = ":Telescope resume<CR>";
        options = {
          desc = "Resume previous search";
          silent = true;
        };
      }
      {
        key = "<leader>f'";
        action = ":Telescope marks<CR>";
        options = {
          desc = "Show bookmarks";
          silent = true;
        };
      }
      {
        key = "<leader>fb";
        action = ":Telescope buffers<CR>";
        options = {
          desc = "Show buffers";
          silent = true;
        };
      }
      {
        key = "<leader>fc";
        action = ":Telescope grep_string<CR>";
        options = {
          desc = "Search word under cursor";
          silent = true;
        };
      }
      {
        key = "<leader>fC";
        action = ":Telescope commands<CR>";
        options = {
          desc = "Show commands";
          silent = true;
        };
      }
      {
        key = "<leader>ff";
        action = ":Telescope find_files<CR>";
        options = {
          desc = "Find files";
          silent = true;
        };
      }
      {
        key = "<leader>fF";
        action = ":Telescope find_files hidden=true<CR>";
        options = {
          desc = "Find files (including hidden)";
          silent = true;
        };
      }
      {
        key = "<leader>fh";
        action = ":Telescope help_tags<CR>";
        options = {
          desc = "Show help tags";
          silent = true;
        };
      }
      {
        key = "<leader>fk";
        action = ":Telescope keymaps<CR>";
        options = {
          desc = "Show keymaps";
          silent = true;
        };
      }
      {
        key = "<leader>fm";
        action = ":Telescope man_pages<CR>";
        options = {
          desc = "Show man pages";
          silent = true;
        };
      }
      {
        key = "<leader>fn";
        action = ":Telescope notify<CR>";
        options = {
          desc = "Show notifications";
          silent = true;
        };
      }
      {
        key = "<leader>fo";
        action = ":Telescope oldfiles<CR>";
        options = {
          desc = "Show recently opened files";
          silent = true;
        };
      }
      {
        key = "<leader>fr";
        action = ":Telescope registers<CR>";
        options = {
          desc = "Show registers";
          silent = true;
        };
      }
      {
        key = "<leader>ft";
        action = ":Telescope colorscheme<CR>";
        options = {
          desc = "Show colorschemes";
          silent = true;
        };
      }
      {
        key = "<leader>fw";
        action = ":Telescope live_grep<CR>";
        options = {
          desc = "Search text";
          silent = true;
        };
      }
      {
        key = "<leader>fW";
        action = ":Telescope live_grep hidden=true<CR>";
        options = {
          desc = "Search text (включая скрытые файлы)";
          silent = true;
        };
      }
      {
        key = "<leader>g";
        action = "+git";
        options = {
          desc = " Git";
          silent = true;
        };
      }
      {
        # key = "<leader>gb";
        # action = ":Telescope git_branches<CR>";
        # options = { desc = "Show Git branches"; silent = true; };
        mode = "n";
        key = "<leader>gb";
        action = "<cmd>BlameToggle<CR>";
        options = {
          desc = "GitBlame";
          silent = true;
        };
      }
      {
        key = "<leader>gc";
        action = ":Telescope git_commits<CR>";
        options = {
          desc = "Show Git commits";
          silent = true;
        };
      }
      {
        key = "<leader>gC";
        action = ":Telescope git_bcommits<CR>";
        options = {
          desc = "Show commits of current file";
          silent = true;
        };
      }
      {
        key = "<leader>l";
        action = "+lsp";
        options = {
          desc = "LSP";
          silent = true;
        };
      }
      {
        key = "<leader>ls";
        action = ":Telescope lsp_document_symbols<CR>";
        options = {
          desc = "Show document symbols";
          silent = true;
        };
      }
      {
        key = "<leader>lG";
        action = ":Telescope lsp_workspace_symbols<CR>";
        options = {
          desc = "Show workspace symbols";
          silent = true;
        };
      }
      # Terminal Mappings
      {
        key = "<leader>t";
        action = "+terminal";
        options = {
          desc = "Terminal";
          silent = true;
        };
      }
      {
        key = "<leader>tf";
        action = ":FloatermNew<CR>";
        options = {
          desc = "Open floating terminal";
          silent = true;
        };
      }
      {
        key = "<F7>";
        action = ":FloatermNew<CR>";
        options = {
          desc = "Open floating terminal";
          silent = true;
        };
      }
      {
        key = "<leader>th";
        action = ":split | terminal<CR>";
        options = {
          desc = "Open horizontal terminal";
          silent = true;
        };
      }
      {
        key = "<leader>tv";
        action = ":vsplit | terminal<CR>";
        options = {
          desc = "Open vertical terminal";
          silent = true;
        };
      }
      {
        key = "<leader>tl";
        action = ":FloatermNew lazygit<CR>";
        options = {
          desc = "Open floating terminal with lazygit";
          silent = true;
        };
      }
      {
        key = "<leader>tn";
        action = ":FloatermNew node<CR>";
        options = {
          desc = "Open floating terminal с node";
          silent = true;
        };
      }
      {
        key = "<leader>tp";
        action = ":FloatermNew python<CR>";
        options = {
          desc = "Open floating terminal with python";
          silent = true;
        };
      }
      {
        key = "<leader>tt";
        action = ":FloatermNew btm<CR>";
        options = {
          desc = "Open floating terminal с btm";
          silent = true;
        };
      }
      # UI/UX Mappings
      {
        key = "<leader>u";
        action = "+UI/UX";
        options = {
          desc = "UI/UX";
          silent = true;
        };
        # action = "+ui";
      }
      {
        mode = "n";
        key = "<leader>d?";
        action.__raw = ''
          function()
          vim.ui.input({ prompt = "Expression: " }, function(expr)
          if expr then require("dapui").eval(expr, { enter = true }) end
          end)
          end
        '';
        options = {
          desc = "Evaluate expression";
          silent = true;
        };
      }
    ];
  };
}
