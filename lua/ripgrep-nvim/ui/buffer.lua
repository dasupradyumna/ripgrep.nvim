-------------------------------------------- UI BUFFERS --------------------------------------------

local M = {}

---writes entries to specified buffer
---@param buffer integer target buffer ID
---@param lines string[] list of entries to write
---@param first? integer start of writing range (defaults to 0)
---@param last? integer end of writing range (defaults to -1)
local function write(buffer, lines, first, last)
  vim.api.nvim_buf_set_lines(buffer, first or 0, last or -1, true, lines)
end

---@class RipgrepNvimPromptBuffer
---@field id? integer prompt buffer ID
---@field prefix string prompt prefix
M.prompt = setmetatable({ prefix = ' Pattern: ' }, {
  ---automatically create buffer if it does not exist
  ---@param self RipgrepNvimPromptBuffer
  ---@return integer # created buffer ID
  __index = function(self)
    self.id = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_create_autocmd('BufWipeout', {
      desc = 'Reset the prompt buffer handle',
      group = 'ripgrep_nvim',
      buffer = self.id,
      callback = function() self.id = nil end,
    })

    vim.bo[self.id].buftype = 'prompt'
    vim.fn.prompt_setprompt(self.id, self.prefix)
    vim.keymap.set('i', '<CR>', '', { buffer = self.id }) -- disable <Enter> prompt callback

    return self.id
  end,
})

---setup the prompt buffer with autocommands and keymaps
---@param directory string search directory
---@param close_ui fun() closes the UI layout
function M.prompt:setup(directory, close_ui)
  local job = require 'ripgrep-nvim.job'

  -- watch changes in prompt text
  vim.api.nvim_create_autocmd({ 'TextChangedI', 'TextChangedP' }, {
    desc = 'Watch the text changes in prompt buffer for processing',
    group = 'ripgrep_nvim',
    buffer = self.id,
    callback = function()
      job:kill()
      M.results:reset()

      local pattern = vim.api.nvim_get_current_line():sub(self.prefix:len() + 1)
      if pattern == '' then return end

      job:spawn(pattern, directory, M.results.update)
    end,
  })

  -- keymaps to exit search
  local function exit()
    job:kill()
    self:reset()
    M.results:reset()
    close_ui()
  end
  vim.keymap.set('i', '<Esc>', exit, { buffer = self.id })
  vim.keymap.set('i', '<C-C>', exit, { buffer = self.id })

  -- TODO: keymaps for navigating entries
end

---reset the prompt buffer state
function M.prompt:reset()
  write(self.id, {})
  vim.bo[self.id].modified = false
end

---@class RipgrepNvimResultsBuffer
---@field id? integer results buffer ID
---@field empty boolean indicates if no results have been found
M.results = setmetatable({ empty = true }, {
  ---automatically create buffer if it does not exist
  ---@param self RipgrepNvimResultsBuffer
  ---@return integer # created buffer ID
  __index = function(self)
    self.id = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_create_autocmd('BufWipeout', {
      desc = 'Reset the results buffer handle',
      group = 'ripgrep_nvim',
      buffer = self.id,
      callback = function()
        self.id = nil
        self.empty = true
      end,
    })

    vim.bo[self.id].buftype = 'nofile'

    return self.id
  end,
})

---updates the buffer content with matches from search job
---@param matches string[] list of matches
function M.results.update(matches)
  if vim.tbl_isempty(matches) then return end

  local self = M.results
  local start = -1
  if self.empty then
    self.empty = false
    start = 0
  end

  write(self.id, matches, start)
end

---resets the buffer contents
function M.results:reset()
  write(self.id, {})
  self.empty = true
end

return M
