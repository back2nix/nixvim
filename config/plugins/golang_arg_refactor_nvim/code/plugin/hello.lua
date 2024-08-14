-- Logging function
local function log(message)
	local log_file = io.open(vim.fn.stdpath("data") .. "/golang_arg_refactor_nvim.log", "a")
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
	log("Attempting to start golang_arg_refactor_nvim RPC server")

	local plugin_path = vim.fn.exepath("golang_arg_refactor_nvim")
	if plugin_path == "" then
		log("golang_arg_refactor_nvim not found in PATH")
		return nil
	end

	log("Plugin path: " .. plugin_path)
	jobid = vim.fn.jobstart({ plugin_path }, {
		rpc = true,
		on_stderr = function(_, data)
			for _, line in ipairs(data) do
				log("golang_arg_refactor_nvim stderr: " .. line)
			end
		end,
		on_exit = function(_, exit_code)
			log("golang_arg_refactor_nvim exited with code: " .. exit_code)
			jobid = nil
		end,
	})

	if jobid <= 0 then
		log("Failed to start golang_arg_refactor_nvim RPC server. Error code: " .. jobid)
		return nil
	end
	log("Successfully started golang_arg_refactor_nvim RPC server")
	return jobid
end

vim.api.nvim_create_user_command("AddArgument", function()
	vim.ui.input({ prompt = "Enter argument name and type (separated by space): " }, function(input)
		if not input or input == "" then
			print("Input must be non-empty")
			return
		end
		local arg_name, arg_type = input:match("(%S+)%s+(%S+)")
		if not arg_name or not arg_type then
			print("Invalid input format. Please provide both argument name and type.")
			return
		end

		local json_result, err = vim.fn.rpcrequest(ensure_job(), "addArgument", { arg_name, arg_type })
		if err then
			log("Error adding argument: " .. tostring(err))
			vim.notify("Error adding argument: " .. tostring(err), vim.log.levels.ERROR)
			return
		end

		local success, result = pcall(vim.fn.json_decode, json_result)
		if not success then
			log("Error decoding JSON result: " .. tostring(result))
			vim.notify("Error decoding result", vim.log.levels.ERROR)
			return
		end

		if result.success then
			log("Argument added successfully: " .. result.message)
			vim.notify(result.message, vim.log.levels.INFO)
		else
			log("Error adding argument: " .. (result.error or "Unknown error"))
			vim.notify(result.error or "Unknown error", vim.log.levels.ERROR)
		end
	end)
end, {})
