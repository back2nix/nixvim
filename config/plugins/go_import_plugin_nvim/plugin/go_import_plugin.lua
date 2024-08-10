local M = {}

-- Module variables
local chan
local jobid

-- Logging function
local function log(message)
	local log_file = io.open(vim.fn.stdpath("data") .. "/go_import_plugin.log", "a")
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
	log("Attempting to start go_import_plugin RPC server")

	local plugin_path = vim.fn.exepath("go_import_plugin")
	if plugin_path == "" then
		log("go_import_plugin not found in PATH")
		return nil
	end

	log("Plugin path: " .. plugin_path)
	jobid = vim.fn.jobstart({ plugin_path }, {
		rpc = true,
		on_stderr = function(_, data)
			for _, line in ipairs(data) do
				log("go_import_plugin stderr: " .. line)
			end
		end,
		on_exit = function(_, exit_code)
			log("go_import_plugin exited with code: " .. exit_code)
			jobid = nil
		end,
	})

	if jobid <= 0 then
		log("Failed to start go_import_plugin RPC server. Error code: " .. jobid)
		return nil
	end
	log("Successfully started go_import_plugin RPC server")
	return jobid
end

-- RPC request with timeout
local function rpc_request_with_timeout(method, args, timeout)
	local job = ensure_job()
	if not job then
		log("Failed to ensure RPC server job")
		return nil, "Failed to start RPC server"
	end

	local result
	local ok, err = pcall(function()
		result = vim.fn.rpcrequest(job, method, unpack(args))
	end)

	if not ok then
		log("RPC request error: " .. tostring(err))
		return nil, err
	end

	return result, nil
end

-- Main functionality
function M.add_import()
	log("Entering add_import function")
	local word = vim.fn.expand("<cword>")
	log("Attempting to add import for word: " .. word)

	local result, err = rpc_request_with_timeout("addImport", { word }, 5000)
	if err then
		log("Error adding import: " .. tostring(err))
		print("Error adding import: " .. tostring(err))
	else
		log("Import added successfully")
		print("Import added successfully")
	end
end

-- Setup function
function M.setup()
	log("Setting up go_import_plugin")
	ensure_job() -- Start the RPC server during setup
end

vim.api.nvim_create_user_command("AddImport", function(args)
	local word = vim.fn.expand("<cword>")
	log("Attempting to add import for word: " .. word)
	local cwd = vim.fn.getcwd()
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

log("go_import_plugin loaded successfully")
return M
