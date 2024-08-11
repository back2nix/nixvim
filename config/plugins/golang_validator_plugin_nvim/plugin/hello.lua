local function log(message)
	local log_file = io.open(vim.fn.stdpath("data") .. "/golang_validator_plugin_nvim.log", "a")
	if log_file then
		log_file:write(os.date("%Y-%m-%d %H:%M:%S ") .. message .. "\n")
		log_file:close()
	end
end

local function ensure_job()
	if vim.g.golang_validator_jobid and vim.fn.jobwait({ vim.g.golang_validator_jobid }, 0)[1] == -1 then
		log("RPC server already running")
		return vim.g.golang_validator_jobid
	end
	log("Attempting to start golang_validator_plugin_nvim RPC server")

	local plugin_path = vim.fn.exepath("golang_validator_plugin_nvim")
	if plugin_path == "" then
		log("golang_validator_plugin_nvim not found in PATH")
		return nil
	end

	log("Plugin path: " .. plugin_path)
	vim.g.golang_validator_jobid = vim.fn.jobstart({ plugin_path }, {
		rpc = true,
		on_stderr = function(_, data)
			for _, line in ipairs(data) do
				log("golang_validator_plugin_nvim stderr: " .. line)
			end
		end,
		on_exit = function(_, exit_code)
			log("golang_validator_plugin_nvim exited with code: " .. exit_code)
			vim.g.golang_validator_jobid = nil
		end,
	})

	if vim.g.golang_validator_jobid <= 0 then
		log("Failed to start golang_validator_plugin_nvim RPC server. Error code: " .. vim.g.golang_validator_jobid)
		return nil
	end
	log("Successfully started golang_validator_plugin_nvim RPC server")
	return vim.g.golang_validator_jobid
end

local function add_validator_tags()
	log("Entering add_validator_tags function")
	local file_path = vim.fn.expand("%:p")
	log("Attempting to add validator tags for file: " .. file_path)

	local job = ensure_job()
	if not job then
		log("Failed to ensure RPC server job")
		print("Failed to start RPC server")
		return
	end

	local result, err = vim.fn.rpcrequest(job, "addValidatorTags", { file_path })
	if err then
		log("Error adding validator tags: " .. tostring(err))
		print("Error adding validator tags: " .. tostring(err))
	else
		log("Validator tags added successfully")
		print(result)
		vim.cmd("e") -- Reload the buffer to show changes
	end
end

local function setup()
	log("Setting up golang_validator_plugin_nvim")
	ensure_job() -- Start the RPC server during setup
end

vim.api.nvim_create_user_command("AddValidatorTags", function()
	local current_file = vim.fn.expand("%:p")
	local buffer_content = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
	local result, err = vim.fn.rpcrequest(ensure_job(), "addValidatorTags", { current_file, buffer_content })
	if err then
		print("Error: " .. err)
	end
end, {})

log("golang_validator_plugin_nvim loaded successfully")
