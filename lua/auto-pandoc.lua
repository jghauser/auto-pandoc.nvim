--
-- PANDOC AUTO
--

local fn = vim.fn
local loop = vim.loop
local api = vim.api

M = {}

local function get_args()
  local cur_pos = api.nvim_win_get_cursor(0)
	local lnr_from = fn.search([[^pandoc_:$]])
  local lnr_until = fn.search([[^\S]]) - 1
  local lines = api.nvim_buf_get_lines(0, lnr_from, lnr_until, true)
  local parameters = {}
  for _,v in ipairs(lines) do
    local line = string.sub(v, 5)
	  local key, value = string.match(line, '^(.*): (.*)')
    parameters[key] = value
  end
  api.nvim_win_set_cursor(0, cur_pos)
  local args = {'--output=' .. fn.expand([[%:p:r]]) .. '.' .. parameters['to']}
  for k,v in pairs(parameters) do
    if v == 'true' then
      table.insert(args, '--' .. k)
    else
      table.insert(args, '--' .. k .. '=' .. v)
    end
  end
  table.insert(args, fn.expand([[%:p]]))
  return args
end

function M.run_pandoc()
  if fn.search([[^pandoc_:$]], 'n') == 0 then
    print('Pandoc yaml block missing!')
    return
  end
  loop.spawn('pandoc', {
    args = get_args()
  },
  function()
    print('Pandoc conversion complete')
  end
  )
end

function M.print_command()
  local args = get_args()
  print(vim.inspect(args))
end

return M
