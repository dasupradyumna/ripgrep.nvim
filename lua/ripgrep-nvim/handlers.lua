------------------------------------------ SEARCH HANDLERS -----------------------------------------

local config = require 'ripgrep-nvim.config'
local job = require 'ripgrep-nvim.job'
local state = require 'ripgrep-nvim.state'
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

local results = {
  ---@type integer index indicating the current entry in list of entries
  current = 0,
  ---@type RipgrepNvimResultEntry[] list of entries aggregated from search results
  entries = {},
}

---sets the current entry in the results buffer to specified index
---@param index integer target entry
function results:set_current(index)
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
  local file, line = raw:match(require('ripgrep-nvim.config').options.format)
  local add_to_temp = vim.fn.bufexists(file) == 0
  local buffer = vim.fn.bufadd(file)
  if add_to_temp then table.insert(state.buffer.temp, buffer) end
  return { file = file, buffer = buffer, line = tonumber(line) }
end

---creates a display line for a result entry
---@param entry RipgrepNvimResultEntry
local function entry_to_line(entry)
  local file = entry.file:match(('^%s[\\/](.+)$'):format(state.directory))
  return ('   %s [%d]'):format(file, entry.line)
end

---updates the buffer content with matches from search job
---@param matches string[] list of matches
function results.update(matches)
  if vim.tbl_isempty(matches) then return end

  local start
  local entries = vim.tbl_map(create_entry, matches)
  vim.list_extend(results.entries, entries)
  if results.current == 0 then -- first set of entries
    results:set_current(1)
    start = 0 -- ensures the blank line in empty buffer is overwritten
    vim.wo[state.float.results].cursorline = true
  end
  local lines = vim.tbl_map(entry_to_line, entries)
  write_to(state.buffer.results, lines, start or -1)
end

---resets the results buffer state
function results:reset()
  vim.api.nvim_win_set_buf(state.float.preview, state.buffer.preview)
  write_to(state.buffer.results, { '   --- No matches found ---' })
  vim.wo[state.float.results].cursorline = false
  self.current = 0
  self.entries = {}
end

---returns the current search string from the prompt
local function get_prompt()
  local pattern = vim.api.nvim_buf_get_lines(state.buffer.prompt, 0, 1, true)[1]
  return pattern:sub(config.options.prefix:len() + 3)
end

---callback executed when the prompt changes
function M.on_prompt_changed()
  job:kill()
  results:reset()

  local pattern = get_prompt()
  if pattern == '' then return end

  job:spawn(pattern, state.directory, results.update)
end

local layout = {
  ---@type 'prompt' | 'preview' UI components that are navigable
  current = 'prompt',
}

---navigate the search UI components
---@param where 'prompt' | 'preview' target UI component
function layout.go_to(where)
  if layout.current == 'preview' then
    vim.cmd 'write' -- TODO: make this configurable
    vim.api.nvim_set_current_win(state.float[where])
    M.on_prompt_changed()
    vim.cmd 'startinsert!'
  elseif where == 'preview' then
    if get_prompt() == '' then return end
    vim.api.nvim_set_current_win(state.float.preview)
    vim.cmd 'stopinsert'
  end

  layout.current = where
end
M.go_to = layout.go_to

---reset the prompt buffer state
local function reset_prompt()
  write_to(state.buffer.prompt, {})
  vim.bo[state.buffer.prompt].modified = false
end

---resets the list of temporary buffers
local function reset_temp_buffers()
  for _, buffer in ipairs(state.buffer.temp) do
    pcall(vim.api.nvim_buf_delete, buffer, { force = true })
  end
  state.buffer.temp = {}
end

---closes layout and resets internal state when search is exited
function M.stop()
  ui.close()
  job:kill()
  reset_prompt()
  reset_temp_buffers()
  if layout.current ~= 'preview' then vim.cmd 'stopinsert' end

  -- delete all global keymaps
  vim.keymap.del('n', '<LocalLeader>p')
  vim.keymap.del('n', '<LocalLeader>q')
  vim.keymap.set('n', '<C-W>', '')
end

---selects the adjacent entry in the list of results
---@param direction 1 | -1 +1 = next entry, -1 = previous entry
function M.choose_entry(direction)
  if results.current > 0 then
    results:set_current((results.current - 1 + direction + #results.entries) % #results.entries + 1)
  end
end

---executed after opening UI
function M.start()
  results:reset()

  vim.keymap.set('n', '<LocalLeader>p', function() layout.go_to 'prompt' end)
  vim.keymap.set('n', '<LocalLeader>q', M.stop)

  -- disable window navigation when UI is open
  vim.keymap.set('n', '<C-W>', '')
end

return M
