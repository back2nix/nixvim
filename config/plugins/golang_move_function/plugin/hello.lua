local chan

local function ensure_job()
	if chan then
		return chan
	end
	chan = vim.fn.jobstart({ "golang_move_function" }, { rpc = true })
	return chan
end

vim.api.nvim_create_user_command("MoveFunction", function()
	vim.ui.input({ prompt = "Enter destination path: " }, function(input)
		if input then
			vim.fn.rpcrequest(ensure_job(), "moveFunction", { input })
		end
	end)
end, {})

-- Set up key mapping
-- vim.api.nvim_set_keymap("n", "<leader>mF", ":MoveFunction<CR>", { noremap = true, silent = true })
