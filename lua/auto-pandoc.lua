--
-- AUTO PANDOC
--

local fn = vim.fn
local api = vim.api
local cmd = vim.cmd

local ERROR = vim.log.levels.ERROR

local function on_exit(job_id, code, _)
	if code == 0 then
		vim.notify("Pandoc conversion complete")
	else
		vim.notify("Pandoc conversion error: " .. job_id:stderr_result()[1], ERROR)
	end
end

M = {}

---@param s string
local function trim(s)
	return (s:gsub("^%s*(.-)%s*$", "%1"))
end

---@param params table
---@param line string
local function parse_line(params, line)
	local indent_pos, _ = string.find(line, "%S")
	if indent_pos == nil then
		vim.notify("[auto-pandoc] yaml empty line:\n" .. line, ERROR)
		return
	end
	if line:sub(indent_pos, indent_pos) == "#" then
		return -- comment line, success
	end

	local indent = (indent_pos - 1) / 2
	if indent % 1 ~= 0 then
		vim.notify("[auto-pandoc] YAML indentation error:\n" .. line, ERROR)
		return
	end

	if indent ~= 1 then
		vim.notify("[auto-pandoc] only support indentation level of 1 for now:\n" .. line, ERROR)
		return
	end

	line = trim(line)
	local key, value = string.match(line, "^(.*):(.*)")

	key = trim(key)
	if key:sub(1, 2) == "- " then
		key = key:sub(3)
	end
	value = trim(value)
	params[key] = value
end

local function get_args()
	local cur_pos = api.nvim_win_get_cursor(0)
	local lnr_from = fn.search([[^pandoc_:$]])
	local lnr_until = fn.search([[^\S]]) - 1
	local lines = api.nvim_buf_get_lines(0, lnr_from, lnr_until, true)
	local parameters = {}
	for _, v in ipairs(lines) do
		parse_line(parameters, v)
	end
	api.nvim_win_set_cursor(0, cur_pos)
	local args = {}
	if parameters["output"] == nil then
		vim.notify("Field `output` not specified, export failed", ERROR)
		return {}
	end
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
		vim.notify("Pandoc yaml block missing!", ERROR)
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
