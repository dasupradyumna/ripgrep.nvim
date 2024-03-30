--------------------------------------- UI COMPONENT HANDLES ---------------------------------------

local M = {}

---@class RipgrepNvimUIBuffers
---@field prompt? integer prompt buffer ID
---@field results? integer results buffer ID
---@field preview? integer preview buffer ID
M.buffer = setmetatable({}, {
  ---automatically create buffer if it does not exist
  ---@param self RipgrepNvimUIBuffers
  ---@param field 'prompt' | 'results' | 'preview' valid keys
  ---@return integer # created buffer ID
  __index = function(self, field)
    if not vim.list_contains({ 'prompt', 'results', 'preview' }, field) then return end

    self[field] = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_create_autocmd('BufWipeout', {
      desc = ('Reset the %s buffer handle'):format(field),
      group = 'ripgrep_nvim',
      buffer = self[field],
      callback = function() self[field] = nil end,
    })
    vim.bo[self[field]].buftype = 'nofile'

    if field == 'prompt' then
      vim.bo[self.prompt].buftype = 'prompt'
      vim.keymap.set('i', '<CR>', '', { buffer = self.prompt }) -- disable <Enter> prompt callback
    elseif field == 'preview' then
      -- TODO: add 'No entry selected' placeholder content
    end

    return self[field]
  end,
})

---@class RipgrepNvimUIFloats
---@field prompt? integer prompt floating window ID
---@field results? integer results floating window ID
---@field preview? integer preview floating window ID
M.float = {}

return M
