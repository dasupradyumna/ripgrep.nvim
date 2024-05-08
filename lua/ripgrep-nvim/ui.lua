------------------------------------------ USER INTERFACE ------------------------------------------

local state = require 'ripgrep-nvim.state'

local M = {}

---open all the UI layout floating windows
function M.open()
  local cfg = {
    relative = 'editor',
    border = 'rounded',
    focusable = false,
    style = 'minimal',
    title = '',
    title_pos = 'center',
  }

  -- overall layout dimensions
  -- FIX: handle tabline, winbar and statusline options for setting below options
  local l_row, l_col, l_height, l_width = 0, 0, vim.o.lines - 4, vim.o.columns - 2

  -- open prompt window, enter it and start insert mode
  cfg = vim.tbl_extend('force', cfg, { height = 1, width = l_width, row = l_row, col = l_col })
  cfg.title = (' Search: %s '):format(state.directory)
  state.float.prompt = vim.api.nvim_open_win(state.buffer.prompt, true, cfg)
  cfg.title = ''
  vim.cmd 'startinsert!'

  -- open results window without entering
  local width = math.floor(l_width * 0.4) - 1
  cfg = vim.tbl_extend('force', cfg, { height = l_height - 3, row = l_row + 3, width = width })
  state.float.results = vim.api.nvim_open_win(state.buffer.results, false, cfg)

  -- open preview window without entering
  cfg = vim.tbl_extend('force', cfg, { col = l_col + width + 2, width = l_width - width - 2 })
  cfg.style = nil
  state.float.preview = vim.api.nvim_open_win(state.buffer.preview, false, cfg)
end

---close the UI layout
function M.close()
  for type, win in pairs(state.float) do
    state.float[type] = nil
    pcall(vim.api.nvim_win_close, win, true)
  end
end

return M
