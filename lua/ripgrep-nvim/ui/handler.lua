-------------------------------------------- UI BUFFERS --------------------------------------------

local id = require 'ripgrep-nvim.ui.id'

local M = {}

---writes entries to specified buffer
---@param buffer integer target buffer ID
---@param lines string[] list of entries to write
---@param first? integer start of writing range (defaults to 0)
---@param last? integer end of writing range (defaults to -1)
local function write(buffer, lines, first, last)
  vim.api.nvim_buf_set_lines(buffer, first or 0, last or -1, true, lines)
end

---@class RipgrepNvimPromptHandler
---@field prefix string prompt prefix
M.prompt = { prefix = ' Pattern: ' }

---setup the prompt buffer with autocommands and keymaps
---@param directory string search directory
function M.prompt:setup(directory)
  local job = require 'ripgrep-nvim.job'

  -- reset results buffer and entries
  M.results:reset()

  -- set prompt prefix
  vim.fn.prompt_setprompt(id.buffer.prompt, self.prefix)

  -- watch changes in prompt text
  vim.api.nvim_create_autocmd({ 'TextChangedI', 'TextChangedP' }, {
    desc = 'Watch the text changes in prompt buffer for processing',
    group = 'ripgrep_nvim',
    buffer = id.buffer.prompt,
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
    require('ripgrep-nvim.ui.layout').close()
    job:kill()
    self:reset()
    M.temp:wipe()
    vim.cmd.stopinsert()
  end
  vim.keymap.set('i', '<Esc>', exit, { buffer = id.buffer.prompt })
  vim.keymap.set('i', '<C-C>', exit, { buffer = id.buffer.prompt })

  -- keymaps to navigate entries
  vim.keymap.set('i', '<C-N>', function() M.results:choose(1) end, { buffer = id.buffer.prompt })
  vim.keymap.set('i', '<C-P>', function() M.results:choose(-1) end, { buffer = id.buffer.prompt })
end

---reset the prompt buffer state
function M.prompt:reset()
  write(id.buffer.prompt, {})
  vim.bo[id.buffer.prompt].modified = false
end

---@class RipgrepNvimTempsHandler
---@field buffers integer[] list of temporary buffer IDs to wipe upon exiting search
M.temp = { buffers = {} }

---wipes all temporary buffers
function M.temp:wipe()
  for _, buffer in ipairs(self.buffers) do
    pcall(vim.api.nvim_buf_delete, buffer, {})
  end
  self.buffers = {}
end

---@class RipgrepNvimResultsHandler
---@field current integer index indicating the current entry in list of entries
---@field entries RipgrepNvimResultEntry[] list of entries aggregated from search results
M.results = { current = 0, entries = {} }

---creates a match item from raw result line
---@param raw string raw line result from ripgrep
---@return RipgrepNvimResultEntry
local function create_entry(raw)
  local filename, line = raw:match(require('ripgrep-nvim.config').options.format)
  local add_to_temp = vim.fn.bufexists(filename) == 0
  local buffer = vim.fn.bufadd(filename)
  if add_to_temp then table.insert(M.temp.buffers, buffer) end
  return { file = filename, buffer = buffer, line = tonumber(line) }
end

---sets the current entry in the results buffer to specified index
---@param index integer target entry
function M.results:set_current(index)
  self.current = index
  local entry = self.entries[self.current]
  vim.api.nvim_win_set_cursor(id.float.results, { self.current, 0 })
  vim.api.nvim_win_set_buf(id.float.preview, math.abs(entry.buffer))
  vim.api.nvim_win_set_cursor(id.float.preview, { entry.line, 0 })
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
  end
  local lines = vim.tbl_map(function(e) return ('   %s [%d]'):format(e.file, e.line) end, entries)
  write(id.buffer.results, lines, start or -1)
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
  vim.api.nvim_win_set_buf(id.float.preview, id.buffer.preview)
  write(id.buffer.results, {})
  self.current = 0
  self.entries = {}
end

return M
