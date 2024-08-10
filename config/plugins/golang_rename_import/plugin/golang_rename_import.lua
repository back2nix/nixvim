-- local chan

-- local function ensure_job()
-- 	if chan then
-- 		return chan
-- 	end
-- 	chan = vim.fn.jobstart({ "golang_rename_import" }, { rpc = true })
-- 	return chan
-- end

-- local function rename_import(args)
-- 	local current_import = vim.fn.expand("<cword>")

-- 	local new_import = vim.fn.input("Enter the new import path: ", current_import)
-- 	print("new_import " .. new_import)
-- 	local result, err = vim.fn.rpcrequest(ensure_job(), "renameImport", { vim.fn.getcwd(), current_import, new_import })
-- 	print("after rpcrequest")
-- 	if err then
-- 		print("Error renaming import: " .. tostring(err))
-- 	else
-- 		print(result)
-- 		vim.cmd("bufdo e")
-- 	end

-- 	-- vim.ui.input({ prompt = "Enter the new import path: ", default = current_import }, function(new_import)
-- 	-- 	print("fuck fuck" .. new_import)

-- 	-- 	if not new_import or new_import == "" or new_import == current_import then
-- 	-- 		print("New import path must be different and non-empty")
-- 	-- 		return
-- 	-- 	end

-- 	-- 	print("fuck fuck 2" .. new_import)

-- 	-- 	local result, err = vim.fn.rpcrequest(ensure_job(), "renameImport", {vim.fn.getcwd(), current_import, new_import})

-- 	-- 	if err then
-- 	-- 		print("Error renaming import: " .. tostring(err))
-- 	-- 	else
-- 	-- 		print(result)
-- 	-- 		vim.cmd("bufdo e")
-- 	-- 	end
-- 	-- end)
-- end

-- vim.api.nvim_create_user_command("RenameImport", rename_import, { nargs = 0 })

local function log(message)
	local log_file = io.open(vim.fn.stdpath("data") .. "/golang_rename_import_plugin.log", "a")
	if log_file then
		log_file:write(os.date("%Y-%m-%d %H:%M:%S ") .. message .. "\n")
		log_file:close()
	end
end

local function ensure_job()
	if vim.g.golang_rename_import_jobid and vim.fn.jobwait({ vim.g.golang_rename_import_jobid }, 0)[1] == -1 then
		log("RPC server already running")
		return vim.g.golang_rename_import_jobid
	end
	log("Attempting to start golang_rename_import_plugin RPC server")

	local plugin_path = vim.fn.exepath("golang_rename_import")
	if plugin_path == "" then
		log("golang_rename_import not found in PATH")
		return nil
	end

	log("Plugin path: " .. plugin_path)
	vim.g.golang_rename_import_jobid = vim.fn.jobstart({ plugin_path }, {
		rpc = true,
		on_stderr = function(_, data)
			for _, line in ipairs(data) do
				log("golang_rename_import stderr: " .. line)
			end
		end,
		on_exit = function(_, exit_code)
			log("golang_rename_import exited with code: " .. exit_code)
			vim.g.golang_rename_import_jobid = nil
		end,
	})

	if vim.g.golang_rename_import_jobid <= 0 then
		log("Failed to start golang_rename_import RPC server. Error code: " .. vim.g.golang_rename_import_jobid)
		return nil
	end
	log("Successfully started golang_rename_import RPC server")
	return vim.g.golang_rename_import_jobid
end

local function get_import_under_cursor()
	local line = vim.api.nvim_get_current_line()
	local col = vim.api.nvim_win_get_cursor(0)[2]
	local import_start = line:find('"', 1, true)
	local import_end = line:find('"', import_start + 1, true)
	if import_start and import_end and col >= import_start and col <= import_end then
		return line:sub(import_start + 1, import_end - 1)
	end
	return nil
end

local function get_project_root()
	local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
	if vim.v.shell_error == 0 then
		return git_root
	end
	return vim.fn.getcwd()
end

local function rename_import()
	log("Entering rename_import function")

	local project_root = get_project_root()
	log("Project root: " .. project_root)

	local current_import = get_import_under_cursor() or ""
	log("Current import: " .. current_import)

	local old_import = current_import
	log("Prompting for new import path")

	vim.ui.input({ prompt = "Enter the new import path: ", default = current_import }, function(new_import)
		if not new_import or new_import == "" or new_import == current_import then
			print("New import path must be different and non-empty")
			return
		end

		local result, err =
			vim.fn.rpcrequest(ensure_job(), "renameImport", { vim.fn.getcwd(), current_import, new_import })

		if err then
			print("Error renaming import: " .. tostring(err))
		else
			print(result)
			vim.cmd("bufdo e")
		end
	end)

	-- local new_import = vim.fn.input("Enter the new import path: ", old_import)
	-- log("New import path entered: " .. new_import)

	-- if new_import == "" or new_import == old_import then
	-- 	log("Invalid new import path")
	-- 	print("New import path must be different and non-empty")
	-- 	return
	-- end

	-- log("Attempting to rename import from " .. old_import .. " to " .. new_import)

	-- local job = ensure_job()
	-- if not job then
	-- 	log("Failed to ensure RPC server job")
	-- 	print("Failed to start RPC server")
	-- 	return
	-- end

	-- log("Sending RPC request")
	-- local result, err = vim.rpcrequest(job, "renameImport", { project_root, old_import, new_import })
	-- log("RPC request completed")

	-- if err then
	-- 	log("Error renaming import: " .. tostring(err))
	-- 	print("Error renaming import: " .. tostring(err))
	-- else
	-- 	log("Import renamed successfully")
	-- 	print(result)
	-- 	vim.cmd("bufdo e") -- Reload all buffers to show changes
	-- end
end

vim.api.nvim_create_user_command("RenameImport", rename_import, {})
