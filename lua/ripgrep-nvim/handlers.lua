------------------------------------------ SEARCH HANDLERS -----------------------------------------

local state = require 'ripgrep-nvim.state'
local job = require 'ripgrep-nvim.job'
local ui = require 'ripgrep-nvim.ui'

local M = {}

---writes entries to specified buffer
---@param buffer integer target buffer ID
---@param lines string[] list of entries to write
---@param first? integer start of writing range (defaults to 0)
---@param last? integer end of writing range (defaults to -1)
local function write_to(buffer, lines, first, last)
  vim.api.nvim_buf_set_lines(buffer, first or 0, last or -1, true, lines)
end

---wipes all temporary buffers
local function reset_temp_buffers()
  for buffer, _ in pairs(state.buffer.temp) do
    pcall(vim.api.nvim_buf_delete, buffer, {})
  end
  state.buffer.temp = {}
end

---closes layout and resets internal state when search is exited
local function exit_search()
  ui.close()
  job:kill()
  M.prompt:reset()
  reset_temp_buffers()
  vim.cmd.stopinsert()
end

---@class RipgrepNvimPromptHandler
---@field prefix string prompt prefix
M.prompt = { prefix = ' Pattern: ' }

---setup the prompt buffer with autocommands and keymaps
-- BUG: this is called every time search is started (sets up duplicate autocommands)
function M.prompt:setup()
  -- reset results buffer and entries
  M.results:reset()

  -- set prompt prefix
  vim.fn.prompt_setprompt(state.buffer.prompt, self.prefix)

  -- watch changes in prompt text
  vim.api.nvim_create_autocmd({ 'TextChangedI', 'TextChangedP' }, {
    desc = 'Watch the text changes in prompt buffer for processing',
    group = 'ripgrep_nvim',
    buffer = state.buffer.prompt,
    callback = function()
      job:kill()
      M.results:reset()

      local pattern = vim.api.nvim_get_current_line():sub(self.prefix:len() + 1)
      if pattern == '' then return end

      job:spawn(pattern, state.directory, M.results.update)
    end,
  })

  vim.keymap.set('i', '<Esc>', exit_search, { buffer = state.buffer.prompt })
  vim.keymap.set('i', '<C-C>', exit_search, { buffer = state.buffer.prompt })

  -- keymaps to navigate entries
  vim.keymap.set('i', '<C-N>', function() M.results:choose(1) end, { buffer = state.buffer.prompt })
  vim.keymap.set(
    'i',
    '<C-P>',
    function() M.results:choose(-1) end,
    { buffer = state.buffer.prompt }
  )

  -- TODO: global keymap to move between prompt and preview
end

---reset the prompt buffer state
function M.prompt:reset()
  write_to(state.buffer.prompt, {})
  vim.bo[state.buffer.prompt].modified = false
end

---@class RipgrepNvimResultsHandler
---@field current integer index indicating the current entry in list of entries
---@field entries RipgrepNvimResultEntry[] list of entries aggregated from search results
M.results = { current = 0, entries = {} }

---sets the current entry in the results buffer to specified index
---@param index integer target entry
function M.results:set_current(index)
  self.current = index
  local entry = self.entries[self.current]
  vim.api.nvim_win_set_cursor(state.float.results, { self.current, 0 })
  vim.api.nvim_win_set_buf(state.float.preview, math.abs(entry.buffer))
  vim.api.nvim_win_set_cursor(state.float.preview, { entry.line, 0 })
  vim.wo[state.float.preview].cursorline = true
end

---creates a match item from raw result line
---@param raw string raw line result from ripgrep
---@return RipgrepNvimResultEntry
local function create_entry(raw)
  local filename, line = raw:match(require('ripgrep-nvim.config').options.format)
  local add_to_temp = vim.fn.bufexists(filename) == 0
  local buffer = vim.fn.bufadd(filename)
  if add_to_temp then state.buffer.temp[buffer] = true end
  return { file = filename, buffer = buffer, line = tonumber(line) }
end

---creates a display line for a result entry
---@param entry RipgrepNvimResultEntry
local function entry_to_line(entry)
  local file = entry.file:match(('^%s[\\/](.+)$'):format(state.directory))
  return ('   %s [%d]'):format(file, entry.line)
end

---updates the buffer content with matches from search job
---@param matches string[] list of matches
function M.results.update(matches)
  if vim.tbl_isempty(matches) then return end

  local self, start = M.results, nil
  local entries = vim.tbl_map(create_entry, matches)
  vim.list_extend(self.entries, entries)
  if self.current == 0 then
    self:set_current(1)
    start = 0 -- ensures the blank line in empty buffer is overwritten
    vim.wo[state.float.results].cursorline = true
  end
  local lines = vim.tbl_map(entry_to_line, entries)
  write_to(state.buffer.results, lines, start or -1)
end

---selects the adjacent entry in the list of results
---@param direction 1 | -1 +1 = next entry, -1 = previous entry
function M.results:choose(direction)
  if self.current > 0 then
    self:set_current((self.current - 1 + direction + #self.entries) % #self.entries + 1)
  end
end

---resets the results buffer state
function M.results:reset()
  vim.api.nvim_win_set_buf(state.float.preview, state.buffer.preview)
  write_to(state.buffer.results, { '   --- No matches found ---' })
  vim.wo[state.float.results].cursorline = false
  self.current = 0
  self.entries = {}
end

return M
