---------------------------------------- UI FLOATING WINDOWS ---------------------------------------

---@class RipgrepNvimSearchUIFloat
---@field id? integer results floating window number (if it exists)
local Float = setmetatable({}, {
  ---indexing metatable for floating window IDs
  ---@param self RipgrepNvimSearchUIFloat
  ---@param field 'id' only this value is valid
  ---@return integer
  __index = function(self, field)
    if field ~= 'id' then return end

    local row, height, col, width = unpack(vim.tbl_flatten(vim.tbl_map(function(size)
      local c_size = math.floor(size * 0.9)
      local c_pos = math.floor((size - c_size) / 2 - 1)
      return { c_pos, c_size }
    end, { vim.o.lines, vim.o.columns })))
    self.id = vim.api.nvim_open_win(require('ripgrep-nvim.ui.buffer').id, true, {
      relative = 'editor',
      height = height,
      width = width,
      row = row,
      col = col,
      border = 'rounded',
      title = ' <uninitialized> ',
      title_pos = 'center',
    })

    vim.cmd [[ setlocal nospell cursorline nonumber statuscolumn= signcolumn=yes:1 ]]

    return self.id
  end,
})

---sets the floating window title
---@param title string title string
function Float:set_title(title)
  local config = vim.api.nvim_win_get_config(self.id)
  vim.api.nvim_win_set_config(self.id, vim.tbl_extend('force', config, { title = title }))
end

return Float
