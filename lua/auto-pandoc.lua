--
-- AUTO PANDOC
--

local fn = vim.fn
local api = vim.api
local cmd = vim.cmd

local function on_exit(job_id, code, _)
  vim.schedule(function()
    if code == 0 then
      vim.notify("Pandoc conversion complete")
    else
      vim.notify("Pandoc conversion error: " .. job_id:stderr_result()[1])
    end
  end)
end

M = {}

local function get_args()
	local cur_pos = api.nvim_win_get_cursor(0)
	local lnr_from = fn.search([[^pandoc_:$]])
	local lnr_until = fn.search([[^\S]]) - 1
	local lines = api.nvim_buf_get_lines(0, lnr_from, lnr_until, true)
	local parameters = {}
	for _, v in ipairs(lines) do
		local line = string.sub(v, 5)
		local key, value = string.match(line, "^(.*): (.*)")
		parameters[key] = value
	end
	api.nvim_win_set_cursor(0, cur_pos)
	local args = {}
	if parameters["output"]:sub(1, 1) == "." then
		parameters["output"] = fn.expand([[%:p:r]]) .. parameters["output"]
	end
	for k, v in pairs(parameters) do
		if v == "true" then
			table.insert(args, "--" .. k)
		else
			table.insert(args, "--" .. k .. "=" .. v)
		end
	end
	table.insert(args, fn.expand([[%:p]]))
	return args
end

function M.run_pandoc()
	local cwd = fn.getcwd()
	cmd([[:cd %:p:h]])
	os.execute("cd")
	if fn.search([[^pandoc_:$]], "n") == 0 then
		vim.notify("Pandoc yaml block missing!")
		return
	else
		vim.notify("Pandoc conversion started")
	end
	local Job = require("plenary.job")
	local args = get_args()
	Job:new({
		command = "pandoc",
		args = args,
		on_exit = on_exit,
	}):start()
	cmd(":cd " .. cwd)
end

return M
