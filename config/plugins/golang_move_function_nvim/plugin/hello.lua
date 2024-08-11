local chan
local last_dest_path = nil

local function ensure_job()
	if chan then
		return chan
	end
	chan = vim.fn.jobstart({ "golang_move_function_nvim" }, { rpc = true })
	return chan
end

local function move_code(path)
	vim.fn.rpcrequest(ensure_job(), "moveCode", { path })
	last_dest_path = path
end

-- Create the MoveCode command
vim.api.nvim_create_user_command("MoveCode", function()
	vim.ui.input({ prompt = "Enter destination path: " }, function(input)
		if input then
			move_code(input)
		end
	end)
end, {})

-- Create the RepeatMoveCode command
vim.api.nvim_create_user_command("RepeatMoveCode", function()
	if last_dest_path then
		move_code(last_dest_path)
	else
		print("No previous move to repeat")
	end
end, {})

-- Function to clear last_dest_path
local function clear_last_dest_path()
	last_dest_path = nil
end

-- Set up commands to clear last_dest_path
vim.api.nvim_create_user_command("ClearLastMove", clear_last_dest_path, {})

-- Optionally, you can set up some autocommands to clear last_dest_path
-- but only for specific events that should reset the last move
vim.api.nvim_create_autocmd("BufWritePost", {
	callback = clear_last_dest_path,
})
