---------------------------------------- UI FLOATING WINDOWS ---------------------------------------

local M = {}

---open all the UI layout floating windows
function M.open_all()
  local buffer = require 'ripgrep-nvim.ui.buffer'
  local cfg = { relative = 'editor', border = 'rounded', focusable = false, style = 'minimal' }

  -- overall layout dimensions
  -- FIX: handle tabline, winbar and statusline options for setting below options
  local l_row, l_col, l_height, l_width = 1, 0, vim.o.lines - 5, vim.o.columns - 2

  -- open prompt window, enter it and start insert mode
  cfg = vim.tbl_extend('force', cfg, { height = 1, width = l_width, row = l_row, col = l_col })
  M.prompt = vim.api.nvim_open_win(buffer.prompt.id, true, cfg)
  vim.cmd.startinsert()

  -- open results window without entering
  cfg = vim.tbl_extend('force', cfg, { height = l_height - 3, row = l_row + 3 })
  M.results = vim.api.nvim_open_win(buffer.results.id, false, cfg)

  -- XXX: preview window
end

---sets the floating window title
---@param title string title string
function M.set_title(title)
  local config = vim.api.nvim_win_get_config(M.prompt)
  config.title = title
  config.title_pos = 'center'
  vim.api.nvim_win_set_config(M.prompt, config)
end

---close the UI layout
function M.close_all()
  vim.api.nvim_win_close(M.prompt, true)
  vim.api.nvim_win_close(M.results, true)
  -- XXX: preview window
end

return M
