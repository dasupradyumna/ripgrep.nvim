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

    if field == 'prompt' then
      self.prompt = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_create_autocmd('BufWipeout', {
        desc = 'Reset the prompt buffer handle',
        group = 'ripgrep_nvim',
        buffer = self.prompt,
        callback = function() self.prompt = nil end,
      })

      vim.bo[self.prompt].buftype = 'prompt'
      vim.keymap.set('i', '<CR>', '', { buffer = self.prompt }) -- disable <Enter> prompt callback
    elseif field == 'results' then
      self.results = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_create_autocmd('BufWipeout', {
        desc = 'Reset the results buffer handle',
        group = 'ripgrep_nvim',
        buffer = self.results,
        callback = function() self.results = nil end,
      })

      vim.bo[self.results].buftype = 'nofile'
    elseif field == 'preview' then
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
