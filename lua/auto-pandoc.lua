--
-- AUTO PANDOC
--

local fn = vim.fn
local api = vim.api
local cmd = vim.cmd

local ERROR = vim.log.levels.ERROR

M = {}

---@param string string
local function trim(string)
  return (string:gsub("^%s*(.-)%s*$", "%1"))
end

---@param lines string[]
---@return number|nil #size of indent or nil if error
local function get_yaml_indent(lines)
  local indent_size = 1000000
  for _, line in ipairs(lines) do
    local indent_pos, _ = string.find(line, "%S")
    if indent_pos == nil then
      vim.notify("auto-pandoc: empty line in YAML header:\n" .. line, ERROR)
      return
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

---Parses a line of the YAML header
---@param line string #Line to parse
---@param indent_size number #Size of indent
---@return table|nil #Table if success, nil otherwise
local function parse_line(line, indent_size)
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
  return { key = key, value = value }
end

---Gets arguments from the YAML header and gives errors when options aren't correct
---@return table|nil #Table if success, nil otherwise
local function get_args()
  local cur_pos = api.nvim_win_get_cursor(0)
  local lnr_from = fn.search([[^pandoc_:$]])
  if lnr_from == 0 then
    vim.notify("auto-pandoc: options missing!", ERROR)
    return
  end
  local lnr_until = fn.search([[^\S]]) - 1
  local lines = api.nvim_buf_get_lines(0, lnr_from, lnr_until, true)
  local indent_size = get_yaml_indent(lines)
  if not indent_size then
    return
  end
  local parameters = {}
  for _, v in ipairs(lines) do
    local key_value = parse_line(v, indent_size)
    if key_value then
      parameters[key_value.key] = key_value.value
    else
      return
    end
  end
  api.nvim_win_set_cursor(0, cur_pos)
  local args = {}
  if parameters["output"] == nil then
    vim.notify("auto-pandoc: field `output` not specified, export failed", ERROR)
    return
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

---Main function to run pandoc
function M.run_pandoc()
  local cwd = fn.getcwd()
  cmd([[:cd %:p:h]])
  os.execute("cd")
  local args = get_args()
  if args then
    vim.notify("auto-pandoc: conversion started")
    vim.system(
      { "pandoc", unpack(args) },
      {},
      function(result)
        vim.schedule(function()
          if result.code == 0 then
            vim.notify("auto-pandoc: conversion complete")
          else
            local err_msg = result.stderr and result.stderr:match("[^\r\n]+") or "unknown error"
            vim.notify("auto-pandoc: conversion error: " .. err_msg, ERROR)
          end
        end)
      end
    )
  end
  cmd(":cd " .. cwd)
end

return M
