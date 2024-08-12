-- Module variables
local chan
local jobid

-- Logging function
local function log(message)
	local log_file = io.open(vim.fn.stdpath("data") .. "/golang_import_plugin_nvim.log", "a")
	if log_file then
		log_file:write(os.date("%Y-%m-%d %H:%M:%S ") .. message .. "\n")
		log_file:close()
	end
end

-- Ensure job function
local function ensure_job()
	log("Entering ensure_job function")
	if jobid and vim.fn.jobwait({ jobid }, 0)[1] == -1 then
		log("RPC server already running")
		return jobid
	end
	log("Attempting to start golang_import_plugin_nvim RPC server")

	local plugin_path = vim.fn.exepath("golang_import_plugin_nvim")
	if plugin_path == "" then
		log("golang_import_plugin_nvim not found in PATH")
		return nil
	end

	log("Plugin path: " .. plugin_path)
	jobid = vim.fn.jobstart({ plugin_path }, {
		rpc = true,
		on_stderr = function(_, data)
			for _, line in ipairs(data) do
				log("golang_import_plugin_nvim stderr: " .. line)
			end
		end,
		on_exit = function(_, exit_code)
			log("golang_import_plugin_nvim exited with code: " .. exit_code)
			jobid = nil
		end,
	})

	if jobid <= 0 then
		log("Failed to start golang_import_plugin_nvim RPC server. Error code: " .. jobid)
		return nil
	end
	log("Successfully started golang_import_plugin_nvim RPC server")
	return jobid
end

vim.api.nvim_create_user_command("AddImport", function(args)
	local word = vim.fn.expand("<cword>")
	log("Attempting to add import for word: " .. word)
	local cwd = vim.fn.getcwd()
	-- vim.notify("hello world", vim.log.levels.INFO)
	local result, err = vim.fn.rpcrequest(ensure_job(), "addImport", { word, cwd })
	if err then
		log("Error adding import: " .. tostring(err))
		print("Error adding import: " .. tostring(err))
	else
		log("Import added successfully")
		print("Import added successfully")
	end
	print(result)
end, { nargs = "*" })
