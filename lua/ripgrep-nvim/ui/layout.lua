---------------------------------------- UI FLOATING WINDOWS ---------------------------------------

local id = require 'ripgrep-nvim.ui.id'

local M = {}

---open all the UI layout floating windows
function M.open()
  local cfg = { relative = 'editor', border = 'rounded', focusable = false, style = 'minimal' }

  -- overall layout dimensions
  -- FIX: handle tabline, winbar and statusline options for setting below options
  local l_row, l_col, l_height, l_width = 0, 0, vim.o.lines - 4, vim.o.columns - 2

  -- open prompt window, enter it and start insert mode
  cfg = vim.tbl_extend('force', cfg, { height = 1, width = l_width, row = l_row, col = l_col })
  id.float.prompt = vim.api.nvim_open_win(id.buffer.prompt, true, cfg)
  vim.cmd.startinsert()

  -- open results window without entering
  cfg = vim.tbl_extend('force', cfg, { height = l_height - 3, row = l_row + 3 })
  id.float.results = vim.api.nvim_open_win(id.buffer.results, false, cfg)

  -- XXX: preview window
end

---sets the floating window title
---@param title string title string
function M.set_title(title)
  local config = vim.api.nvim_win_get_config(id.float.prompt)
  config.title = title
  config.title_pos = 'center'
  vim.api.nvim_win_set_config(id.float.prompt, config)
end

---close the UI layout
function M.close()
  vim.api.nvim_win_close(id.float.prompt, true)
  vim.api.nvim_win_close(id.float.results, true)
  -- XXX: preview window
end

return M
