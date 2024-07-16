{
  config,
  inputs,
  lib,
  pkgs,
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
    helpers = inputs.nixvim.lib.${pkgs.system}.helpers;
  in {
    programs.nixvim = {
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
          dapBreakpointRejected = {
            text = " ";
            texthl = "DapBreakpointRejected";
          };
          dapLogPoint = {
            text = "◆";
            texthl = "DapLogPoint";
          };
          dapStopped = {
            text = "󰁕";
            texthl = "DapStopped";
          };
        };
        extensions = {
          dap-ui = {
            enable = true;
            floating.mappings = {
              close = ["<ESC>" "q"];
            };
          };
          dap-virtual-text = {
            enable = true;
          };
        };
      };
      plugins.lualine.sections.lualine_x = lib.mkOrder 900 [
        {
          extraConfig.__raw = ''
            {
              function() return " " .. require("dap").status() end,
              cond = function() return require("dap").status() ~= "" end,
            }
          '';
        }
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
      '';
      keymaps = [
        {
          key = "<leader>dB";
          mode = "n";
          action.__raw = ''function() require("dap").set_breakpoint(vim.fn.input('Breakpoint condition: ')) end'';
          options.desc = "Breakpoint Condition";
        }
        {
          key = "<leader>db";
          mode = "n";
          action.__raw = ''function() require("dap").toggle_breakpoint() end'';
          options.desc = "Toggle Breakpoint";
        }
        {
          key = "<leader>dc";
          mode = "n";
          action.__raw = ''function() require("dap").continue() end'';
          options.desc = "Continue";
        }
        {
          key = "<leader>da";
          mode = "n";
          action.__raw = ''function() require("dap").continue({ before = get_args }) end'';
          options.desc = "Run with Args";
        }
        {
          key = "<leader>dC";
          mode = "n";
          action.__raw = ''function() require("dap").run_to_cursor() end'';
          options.desc = "Run to Cursor";
        }
        {
          key = "<leader>dg";
          mode = "n";
          action.__raw = ''function() require("dap").goto_() end'';
          options.desc = "Go to Line (No Execute)";
        }
        {
          key = "<leader>di";
          mode = "n";
          action.__raw = ''function() require("dap").step_into() end'';
          options.desc = "Step Into";
        }
        {
          key = "<leader>dj";
          mode = "n";
          action.__raw = ''function() require("dap").down() end'';
          options.desc = "Down";
        }
        {
          key = "<leader>dk";
          mode = "n";
          action.__raw = ''function() require("dap").up() end'';
          options.desc = "Up";
        }
        {
          key = "<leader>dl";
          mode = "n";
          action.__raw = ''function() require("dap").run_last() end'';
          options.desc = "Run Last";
        }
        {
          key = "<leader>do";
          mode = "n";
          action.__raw = ''function() require("dap").step_out() end'';
          options.desc = "Step Out";
        }
        {
          key = "<leader>dO";
          mode = "n";
          action.__raw = ''function() require("dap").step_over() end'';
          options.desc = "Step Over";
        }
        {
          key = "<leader>dp";
          mode = "n";
          action.__raw = ''function() require("dap").pause() end'';
          options.desc = "Pause";
        }
        {
          key = "<leader>dr";
          mode = "n";
          action.__raw = ''function() require("dap").repl.toggle() end'';
          options.desc = "Toggle REPL";
        }
        {
          key = "<leader>ds";
          mode = "n";
          action.__raw = ''function() require("dap").session() end'';
          options.desc = "Session";
        }
        {
          key = "<leader>dt";
          mode = "n";
          action.__raw = ''function() require("dap").terminate() end'';
          options.desc = "Terminate";
        }
        {
          key = "<leader>dw";
          mode = "n";
          action.__raw = ''function() require("dap.ui.widgets").hover() end'';
          options.desc = "Widgets";
        }
        {
          key = "<leader>du";
          mode = "n";
          action.__raw = ''function() require("dapui").toggle({ }) end'';
          options.desc = "Dap UI";
        }
        {
          key = "<leader>de";
          mode = ["n" "v"];
          action.__raw = ''function() require("dapui").eval() end'';
          options.desc = "Eval";
        }
      ];
      plugins.which-key.registrations."<leader>d".name = "+debug";
    };
  };
}
