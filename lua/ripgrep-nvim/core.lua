---------------------------------------- CORE FUNCTIONALITY ----------------------------------------

local util = require 'ripgrep-nvim.util'
local Worker = require 'ripgrep-nvim.worker'

local M = {}

---@class RipgrepNvimSearchUI
M.ui = {}

---@class RipgrepNvimSearchUIBuffer
---@field id? integer results buffer number (if it exists)
M.ui.buffer = {}

---temporarily unlocks and writes entries to the buffer
---@param lines string[] list of entries to write
---@param first? integer start of writing range (defaults to 0)
---@param last? integer end of writing range (defaults to -1)
function M.ui.buffer:write(lines, first, last)
  vim.bo[self.id].modifiable = true
  vim.api.nvim_buf_set_lines(self.id, first or 0, last or -1, true, lines)
  vim.bo[self.id].modifiable = false
end

---updates the buffer content with matches from search job
---@param matches string[] list of matches
function M.ui.buffer.update(matches)
  M.ui.buffer:write(matches, -1)

  -- HACK: remove first placeholder line if atleast one result is found
  if M.job.no_results and not vim.tbl_isempty(matches) then
    M.job.no_results = false
    M.ui.buffer:write({}, 0, 1)
  end
end

M.ui.buffer = setmetatable(M.ui.buffer, {
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

---@class RipgrepNvimSearchUIFloat
---@field id? integer results floating window number (if it exists)
M.ui.float = {}

---sets the floating window title
---@param title string title string
function M.ui.float:set_title(title)
  local config = vim.api.nvim_win_get_config(self.id)
  vim.api.nvim_win_set_config(self.id, vim.tbl_extend('force', config, { title = title }))
end

M.ui.float = setmetatable(M.ui.float, {
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
    self.id = vim.api.nvim_open_win(M.ui.buffer.id, true, {
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

---@class RipgrepNvimSearchJob
M.job = {
  ---@type vim.SystemObj? vim.system job handle (when active)
  handle = nil,

  ---@type RipgrepNvimWorker buffer update worker
  worker = Worker(M.ui.buffer.update),

  ---@type boolean indicates if not even one result has been output
  no_results = true,
}

---kills the job (when active) using SIGTERM
function M.job:stop()
  if self.handle then self.handle:kill 'SIGTERM' end
end

---clears old results and starts a new search job
---@param search_pattern string target search pattern
---@param directory string target directory to recursively search
function M.job:start(search_pattern, directory)
  self.worker:start()

  -- constructs a search command
  -- TODO: extract into a command creator function
  local config_command = require('ripgrep-nvim.config').options.command
  local command = vim.deepcopy(config_command.args)
  table.insert(command, 1, config_command.exe)
  vim.list_extend(command, { search_pattern, directory })

  -- starts a new search process
  self.handle = vim.system(command, {
    stdout = function(err, data)
      if err then error(err) end -- backup to catch unexpected errors
      if not data then return end

      self.worker:add(vim.split(data:gsub('\r\n', '\n'), '\n', { trimempty = true }))
    end,
  }, function()
    self.handle = nil
    self.worker:stop()
    self.no_results = true
  end)
end

---search for a custom string received from user input using specified search options
---@param opts? RipgrepNvimSearchOptions search options
function M.search(opts)
  -- validate the search options
  local message = util.validate_arguments {
    {
      'opts',
      { opts },
      function(name, value)
        if type(value) == 'nil' then return end
        if type(value) ~= 'table' then
          return ('Search options "%s" must be a table'):format(name)
        end

        local valid_fields = { 'directory' }
        for field, _ in pairs(value) do
          if not vim.list_contains(valid_fields, field) then
            return ('Unknown field "%s" in "%s". Valid fields: %s'):format(
              field,
              name,
              vim.inspect(valid_fields)
            )
          end
        end
      end,
    },
    { 'opts.directory', { opts, 'directory' }, { 'string', 'nil' } },
  }
  if message then
    util.notify:send('E', {
      '[ripgrep.nvim] ERROR: Invalid search options; search aborted!\n',
      message,
    })
    return
  end

  -- use defaults for missing arguments
  opts = opts or {}
  opts.directory = opts.directory or vim.loop.cwd()

  -- kill existing job if any
  M.job:stop()

  -- clear previous search results
  M.ui.buffer:write { '-- No matches found --' }

  vim.ui.input({ prompt = 'Search pattern: ' }, function(pattern)
    if not pattern or #pattern == 0 then return end

    M.job:start(pattern, opts.directory)

    -- update the results floating window
    vim.api.nvim_win_set_buf(M.ui.float.id, M.ui.buffer.id)
    M.ui.float:set_title((' Search Results: %s '):format(opts.directory))
  end)
end

return M
