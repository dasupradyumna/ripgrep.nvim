-------------------------------------------- UI BUFFERS --------------------------------------------

---@class RipgrepNvimSearchUIBuffer
---@field id? integer results buffer number (if it exists)
---@field no_results? boolean indicates if not even one result has been output
local Buffer = setmetatable({ no_results = true }, {
  ---indexing metatable for buffer IDs
  ---@param self RipgrepNvimSearchUIBuffer
  ---@param field 'id' only this value is valid
  ---@return integer
  __index = function(self, field)
    if field ~= 'id' then return end

    self.id = vim.api.nvim_create_buf(false, true)

    vim.bo[self.id].buftype = 'nofile'
    vim.bo[self.id].modifiable = false

    vim.keymap.set('n', 'q', '<Cmd>quit<CR>', { buffer = self.id })

    vim.api.nvim_create_autocmd(
      'BufWipeout',
      { group = 'ripgrep_nvim', buffer = self.id, callback = function() self.id = nil end }
    )

    return self.id
  end,
})

---temporarily unlocks and writes entries to the buffer
---@param lines string[] list of entries to write
---@param first? integer start of writing range (defaults to 0)
---@param last? integer end of writing range (defaults to -1)
function Buffer:write(lines, first, last)
  vim.bo[self.id].modifiable = true
  vim.api.nvim_buf_set_lines(self.id, first or 0, last or -1, true, lines)
  vim.bo[self.id].modifiable = false
end

---updates the buffer content with matches from search job
---@param matches string[] list of matches
function Buffer.update(matches)
  Buffer:write(matches, -1)

  -- HACK: remove first placeholder line if atleast one result is found
  if Buffer.no_results and not vim.tbl_isempty(matches) then
    Buffer.no_results = false
    Buffer:write({}, 0, 1)
  end
end

---resets the buffer contents
function Buffer:reset()
  Buffer:write { '-- No matches found --' }
  Buffer.no_results = true
end

return Buffer
