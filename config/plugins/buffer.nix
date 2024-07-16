# https://github.com/reyhansofian/nixpkgs/blob/4adf76f2f5bae28758815d6d315c7d609be1bfa0/config/nixvim/keymap.nix#L47
{
  extraConfigLuaPre = ''
    --- Check if a buffer is valid
    ---@param bufnr number? The buffer to check, default to current buffer
    ---@return boolean # Whether the buffer is valid or not
    function buffer_is_valid(bufnr)
      if not bufnr then bufnr = 0 end
      return vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].buflisted
    end

    --- Close a given buffer
    ---@param bufnr? number The buffer to close or the current buffer if not provided
    ---@param force? boolean Whether or not to foce close the buffers or confirm changes (default: false)
    function buffer_close(bufnr, force)
      if not bufnr or bufnr == 0 then bufnr = vim.api.nvim_get_current_buf() end
      local buftype = vim.api.nvim_get_option_value("buftype", { buf = bufnr })
      vim.cmd(("silent! %s %d"):format((force or buftype == "terminal") and "bdelete!" or "confirm bdelete", bufnr))
    end

    --- Close all buffers
    ---@param keep_current? boolean Whether or not to keep the current buffer (default: false)
    ---@param force? boolean Whether or not to foce close the buffers or confirm changes (default: false)
    function buffer_close_all(keep_current, force)
      if keep_current == nil then keep_current = false end
      local current = vim.api.nvim_get_current_buf()
      for _, bufnr in ipairs(vim.t.bufs) do
        if not keep_current or bufnr ~= current then buffer_close(bufnr, force) end
      end
    end

    --- Move the current buffer tab n places in the bufferline
    ---@param n number The number of tabs to move the current buffer over by (positive = right, negative = left)
    function buffer_move(n)
      if n == 0 then return end -- if n = 0 then no shifts are needed
      local bufs = vim.t.bufs -- make temp variable
      for i, bufnr in ipairs(bufs) do -- loop to find current buffer
        if bufnr == vim.api.nvim_get_current_buf() then -- found index of current buffer
          for _ = 0, (n % #bufs) - 1 do -- calculate number of right shifts
            local new_i = i + 1 -- get next i
            if i == #bufs then -- if at end, cycle to beginning
              new_i = 1 -- next i is actually 1 if at the end
              local val = bufs[i] -- save value
              table.remove(bufs, i) -- remove from end
              table.insert(bufs, new_i, val) -- insert at beginning
            else -- if not at the end,then just do an in place swap
              bufs[i], bufs[new_i] = bufs[new_i], bufs[i]
            end
            i = new_i -- iterate i to next value
          end
          break
        end
      end
      vim.t.bufs = bufs -- set buffers
      vim.cmd.redrawtabline() -- redraw tabline
    end

    --- Navigate left and right by n places in the bufferline
    -- @param n number The number of tabs to navigate to (positive = right, negative = left)
    function buffer_nav(n)
      local current = vim.api.nvim_get_current_buf()
      for i, v in ipairs(vim.t.bufs) do
        if current == v then
          vim.cmd.b(vim.t.bufs[(i + n - 1) % #vim.t.bufs + 1])
          break
        end
      end
    end
  '';
}
