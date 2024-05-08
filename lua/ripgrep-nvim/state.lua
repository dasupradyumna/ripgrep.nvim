--------------------------------------- INTERNAL SEARCH STATE --------------------------------------

local M = {}

---@type string path to the current search directory
M.directory = ''

---@class RipgrepNvimUIBuffers
---@field temp integer[] list of temporary buffer IDs
---@field prompt? integer prompt buffer ID
---@field results? integer results buffer ID
---@field preview? integer preview buffer ID
M.buffer = setmetatable({ temp = {} }, {
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
    vim.bo[self[field]].buftype = 'nofile' -- XXX: does this need to moved to ftplugin folder?
    vim.bo[self[field]].filetype = 'ripgrep_nvim_' .. field

    return self[field]
  end,
})

---@class RipgrepNvimUIFloats
---@field prompt? integer prompt floating window ID
---@field results? integer results floating window ID
---@field preview? integer preview floating window ID
M.float = {}

return M
