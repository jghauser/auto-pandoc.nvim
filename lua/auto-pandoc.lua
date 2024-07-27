--
-- AUTO PANDOC
--

local fn = vim.fn
local api = vim.api
local cmd = vim.cmd

local ERROR = vim.log.levels.ERROR

local function on_exit(job_id, code, _)
  vim.schedule(function()
    if code == 0 then
      vim.notify("auto-pandoc: conversion complete")
    else
      vim.notify("auto-pandoc: conversion error: " .. job_id:stderr_result()[1], ERROR)
    end
  end)
end

M = {}

---@param s string
local function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

---@param lines string[]
---@return number indent size of indent, error(-1)
local function get_yaml_indent(lines)
  local indent_size = 1000000
  for _, line in ipairs(lines) do
    local indent_pos, _ = string.find(line, "%S")
    if indent_pos == nil then
      vim.notify("auto-pandoc: empty line in YAML header:\n" .. line, ERROR)
      return -1
    end
    if line:sub(indent_pos, indent_pos) == "#" then
      -- comment line, success
    else
      -- find the smallest indent in yaml
      local local_indent_size = (indent_pos - 1)
      if indent_size > local_indent_size then
        indent_size = local_indent_size
      end
    end
  end
  return indent_size
end

---@param params table
---@param line string
---@param indent_size number
local function parse_line(params, line, indent_size)
  local indent_pos, _ = string.find(line, "%S")
  if indent_pos and line:sub(indent_pos, indent_pos) == "#" then
    return -- comment line, success
  end

  local indent_level = (indent_pos - 1) / indent_size
  if indent_level % 1 ~= 0 then -- make sure it is an integer
    vim.notify("auto-pandoc: YAML indentation error:\n" .. line, ERROR)
    return
  end

  if indent_level ~= 1 then
    vim.notify("auto-pandoc: indentation levels above 1 are unsupported:\n" .. line, ERROR)
    return
  end

  line = trim(line)
  local key, value = string.match(line, "^(.*):(.*)")

  key = trim(key)
  if key:sub(1, 2) == "- " then
    key = key:sub(3)
  end
  -- remove inline comments
  if value:find("#") ~= nil then
    local comment_pos, _ = value:find("#")
    value = value:sub(1, comment_pos - 1)
  end
  value = trim(value)
  params[key] = value
end

local function get_args()
  local cur_pos = api.nvim_win_get_cursor(0)
  local lnr_from = fn.search([[^pandoc_:$]])
  local lnr_until = fn.search([[^\S]]) - 1
  local lines = api.nvim_buf_get_lines(0, lnr_from, lnr_until, true)
  local indent_size = get_yaml_indent(lines)
  if indent_size == -1 then
    return {}
  end
  local parameters = {}
  for _, v in ipairs(lines) do
    parse_line(parameters, v, indent_size)
  end
  api.nvim_win_set_cursor(0, cur_pos)
  local args = {}
  if parameters["output"] == nil then
    vim.notify("auto-pandoc: field `output` not specified, export failed", ERROR)
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
    vim.notify("auto-pandoc: YAML options missing!", ERROR)
    return
  else
    vim.notify("auto-pandoc: conversion started")
  end
  local Job = require("plenary.job")
  local args = get_args()
  if (#args == 0) then
    return
  end
  Job:new({
    command = "pandoc",
    args = args,
    on_exit = on_exit,
  }):start()
  cmd(":cd " .. cwd)
end

return M
