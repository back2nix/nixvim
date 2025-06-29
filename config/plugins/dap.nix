{
  config,
  inputs,
  lib,
  pkgs,
  helpers,
  ...
}: {
  options = {
    nvim.dap = {
      vscode-adapters = lib.mkOption {
        type = with lib.types; attrsOf (listOf str);
        default = {};
        description = ''
          Configure debug adapters to be registered for use with a VS Code launch.json file per file type.
        '';
        example = {
          cppdbg = ["c" "cpp"];
        };
      };
    };
  };

  config = let
    # ИСПРАВЛЕНО: Путь к helpers изменился в nixvim
    # helpers = inputs.nixvim.lib.helpers;

    gdb-args-config = {
      name = "Launch (GDB) with args";
      type = "gdb";
      request = "launch";
      program.__raw = ''
        function()
        return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. '/', "file")
        end
      '';
      args.__raw = ''
        function()
        return vim.split(vim.fn.input("Arguments: "), " ")
        end
      '';
      cwd = ''''${workspaceFolder}'';
      stopOnEntry = false;
    };

    gdb-config = {
      name = "Launch (GDB)";
      type = "gdb";
      request = "launch";
      program.__raw = ''
        function()
        return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. '/', "file")
        end
      '';
      cwd = ''''${workspaceFolder}'';
      stopOnEntry = false;
    };

    lldb-config = {
      name = "Launch (LLDB)";
      type = "lldb";
      request = "launch";
      program.__raw = ''
        function()
            return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. '/', "file")
        end'';
      cwd = ''''${workspaceFolder}'';
      stopOnEntry = false;
    };

    # not working
    # bashdb-5.0-1.1.2/bin/bashdb exited with code: 1
    sh-config = lib.mkIf pkgs.stdenv.isLinux {
      type = "bashdb";
      request = "launch";
      name = "Launch (BashDB)";
      showDebugOutput = true;
      pathBashdb = "${lib.getExe pkgs.bashdbInteractive}";
      pathBashdbLib = "${pkgs.bashdbInteractive}/share/basdhb/lib/";
      trace = true;
      file = ''''${file}'';
      program = ''''${file}'';
      cwd = ''''${workspaceFolder}'';
      pathCat = "cat";
      pathBash = "${lib.getExe pkgs.bashInteractive}";
      pathMkfifo = "mkfifo";
      pathPkill = "pkill";
      args = {};
      env = {};
      terminalKind = "integrated";
    };
  in {
    plugins.dap = {
      enable = true;
      signs = {
        dapBreakpoint = {
          text = " ";
          texthl = "DapBreakpoint";
        };
        dapBreakpointCondition = {
          text = " ";
          texthl = "DapBreakpointCondition";
        };
        dapLogPoint = {
          text = "◆";
          texthl = "DapLogPoint";
        };
        dapStopped = {
          text = "󰁕";
          texthl = "DapStopped";
        };
        dapBreakpointRejected = {
          text = "❌"; # 🟥
          texthl = "DapBreakpointRejected";
        };
      };
      # ИСПРАВЛЕНО: Блок `extensions` устарел. Плагины теперь настраиваются на верхнем уровне.
      # Конфигурация для dap-ui, dap-go и т.д. перенесена ниже.

      configurations = {
        # not working
        # bashdb-5.0-1.1.2/bin/bashdb exited with code: 1
        sh = lib.optionals pkgs.stdenv.isLinux [sh-config];

        c = [lldb-config] ++ lib.optionals pkgs.stdenv.isLinux [gdb-config gdb-args-config];

        cpp =
          [lldb-config]
          ++ lib.optionals pkgs.stdenv.isLinux [
            gdb-config
            gdb-args-config
            # codelldb-config
          ];
      };

      adapters = {
        executables = {
          # not working
          # bashdb-5.0-1.1.2/bin/bashdb exited with code: 1
          bashdb = lib.mkIf pkgs.stdenv.isLinux {command = "${lib.getExe pkgs.bashdbInteractive}";};

          cppdbg = {
            command = "gdb";
            args = [
              "-i"
              "dap"
            ];
          };

          gdb = {
            command = "gdb";
            args = [
              "-i"
              "dap"
            ];
          };

          lldb = {
            command = lib.getExe' pkgs.lldb (
              if pkgs.stdenv.isLinux
              then "lldb-dap"
              else "lldb-vscode"
            );
          };
        };
      };
    };

    # ИСПРАВЛЕНО: Плагины-расширения для dap теперь настраиваются как плагины верхнего уровня.
    plugins.dap-ui = {
      enable = true;
      settings = {
        controls.enabled = true;
        floating.mappings = {
          close = ["<ESC>" "q"];
        };
      };
    };

    plugins.dap-virtual-text.enable = true;

    plugins.dap-python.enable = true;

    plugins.dap-go = {
      enable = true;
      settings = {
        # ИСПРАВЛЕНО: dapConfigurations -> dap_configurations
        dap_configurations = [
          {
            type = "go";
            name = "Attach remote";
            mode = "remote";
            request = "attach";
          }
        ];
        delve = {
          # ИСПРАВЛЕНО: Опции переименованы в snake_case
          path = "dlv";
          initialize_timeout_sec = 20;
          port = "38697";
          build_flags = "";
        };
      };
    };


    # ИСПРАВЛЕНО: `sections` теперь находится внутри `settings`
    plugins.lualine.settings.sections.lualine_x = lib.mkOrder 900 [
      {
        extraConfig.__raw = ''
          {
            function() return " " .. require("dap").status() end,
            cond = function() return require("dap").status() ~= "" end,
          }
        '';
      }
    ];

    extraPlugins = with pkgs.vimPlugins; [
      telescope-dap-nvim
    ];

    extraConfigLua = ''
      -- Automatically open/close dap-ui
      local dap, dapui = require("dap"), require("dapui")
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

      -- Setup VS Code file support
      require("dap.ext.vscode").load_launchjs(nil, ${helpers.toLuaObject config.nvim.dap.vscode-adapters})

      require('dap-python').test_runner = "pytest"
    '';

    keymaps = [
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
        action = ":lua require('dap.ui.widgets').preview()<CR>";
        options = {
          desc = "Preview";
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
      {
        key = "<leader>dtc";
        action = "<cmd>Telescope dap commands<cr>";
        options = {
          desc = "Commands";
          silent = true;
        };
      }
      {
        key = "<leader>dtb";
        action = "<cmd>Telescope dap list_breakpoints<cr>";
        options = {
          desc = "List Breakpointshint";
          silent = true;
        };
      }
      {
        key = "<leader>dtv";
        action = "<cmd>Telescope dap variables<cr>";
        options = {
          desc = "Variables";
          silent = true;
        };
      }
      {
        key = "<leader>dtf";
        action = "<cmd>Telescope dap frames<cr>";
        options = {
          desc = "Frames";
          silent = true;
        };
      }
    ];
  };
}
