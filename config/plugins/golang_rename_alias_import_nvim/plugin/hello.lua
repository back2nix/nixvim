local function log(message)
	local log_file = io.open(vim.fn.stdpath("data") .. "/golang_rename_alias_import_nvim_plugin.log", "a")
	if log_file then
		log_file:write(os.date("%Y-%m-%d %H:%M:%S ") .. message .. "\n")
		log_file:close()
	end
end

local function ensure_job()
	if vim.g.golang_rename_alias_import_nvim_jobid and vim.fn.jobwait({ vim.g.golang_rename_import_jobid }, 0)[1] == -1 then
		log("RPC server already running")
		return vim.g.golang_rename_alias_import_nvim_jobid
	end
	log("Attempting to start golang_rename_alias_import_nvim_plugin RPC server")

	local plugin_path = vim.fn.exepath("golang_rename_alias_import_nvim")
	if plugin_path == "" then
		log("golang_rename_alias_import_nvim not found in PATH")
		return nil
	end

	log("Plugin path: " .. plugin_path)
	vim.g.golang_rename_alias_import_nvim_jobid = vim.fn.jobstart({ plugin_path }, {
		rpc = true,
		on_stderr = function(_, data)
			for _, line in ipairs(data) do
				log("golang_rename_alias_import_nvim stderr: " .. line)
			end
		end,
		on_exit = function(_, exit_code)
			log("golang_rename_alias_import_nvim exited with code: " .. exit_code)
			vim.g.golang_rename_alias_import_nvim_jobid = nil
		end,
	})

	if vim.g.golang_rename_alias_import_nvim_jobid <= 0 then
		log("Failed to start golang_rename_alias_import_nvim RPC server. Error code: " .. vim.g.golang_rename_import_jobid)
		return nil
	end
	log("Successfully started golang_rename_alias_import_nvim RPC server")
	return vim.g.golang_rename_alias_import_nvim_jobid
end

local function get_import_or_alias_under_cursor()
	local job_id = ensure_job()
	if not job_id then
		print("Failed to start RPC server")
		return nil, nil
	end

	local result, err = vim.fn.rpcrequest(job_id, "getImportOrAliasUnderCursor", { vim.fn.expand("%:p") })
	if err then
		print("Error getting import or alias: " .. tostring(err))
		return nil, nil
	end

	if result then
		return result.value, result.kind
	end

	return nil, nil
end

local function rename_import()
	log("Entering rename_import function")

	local value, kind = get_import_or_alias_under_cursor()
	if not value then
		print("No import or alias found under cursor")
		return
	end

	log("Found " .. kind .. ": " .. value)

	rename_alias(value)
end

function rename_alias(current_alias)
	vim.ui.input({ prompt = "Enter the new alias: ", default = current_alias }, function(new_alias)
		if not new_alias or new_alias == "" or new_alias == current_alias then
			print("New alias must be different and non-empty")
			return
		end

		local result, err =
			vim.fn.rpcrequest(ensure_job(), "renameAlias", { vim.fn.expand("%:p"), current_alias, new_alias })

		if err then
			print("Error renaming alias: " .. tostring(err))
		else
			print(result)
			vim.cmd("e") -- Reload the current buffer to show changes
		end
	end)
end

vim.api.nvim_create_user_command("RenameAliasImport", rename_import, {})
