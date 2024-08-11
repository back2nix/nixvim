-- Глобальная переменная для хранения job_id
local job_id = nil

local function ensure_job()
	if job_id then
		return job_id
	end
	job_id = vim.fn.jobstart({ "go_argument_plugin" }, { rpc = true })
	return job_id
end

local function add_argument(func_name, arg_name, arg_type)
	local id = ensure_job()
	vim.rpcrequest(id, "add_argument", func_name, arg_name, arg_type)
end

local function remove_argument(func_name, arg_name)
	local id = ensure_job()
	vim.rpcrequest(id, "remove_argument", func_name, arg_name)
end

-- Настройка команд без использования M
vim.api.nvim_create_user_command("AddArgument", function(opts)
	add_argument(opts.fargs[1], opts.fargs[2], opts.fargs[3])
end, { nargs = 3 })

vim.api.nvim_create_user_command("RemoveArgument", function(opts)
	remove_argument(opts.fargs[1], opts.fargs[2])
end, { nargs = 2 })
