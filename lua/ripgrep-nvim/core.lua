---------------------------------------- CORE FUNCTIONALITY ----------------------------------------

local buffer = require 'ripgrep-nvim.ui.buffer'
local float = require 'ripgrep-nvim.ui.float'
local util = require 'ripgrep-nvim.util'
local Worker = require 'ripgrep-nvim.worker'

local M = {}

---@class RipgrepNvimSearchJob
M.job = {
  ---@type vim.SystemObj? vim.system job handle (when active)
  handle = nil,

  ---@type RipgrepNvimWorker buffer update worker
  worker = Worker(buffer.update),
}

---clears old results and starts a new search job
---@param search_pattern string target search pattern
---@param directory string target directory to recursively search
function M.job:spawn(search_pattern, directory)
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
      -- CHECK: if this can replace worker
      -- local timer = vim.loop.new_timer()
      -- timer:start(10, 0, function()
      --   vim.schedule_wrap(buffer.update)(
      --     vim.split(data:gsub('\r\n', '\n'), '\n', { trimempty = true })
      --   )
      --   timer:close()
      -- end)
    end,
  }, function()
    self.handle = nil
    self.worker:stop()
  end)
end

---kills the job (when active) using SIGTERM
function M.job:kill()
  if self.handle then self.handle:kill 'SIGTERM' end
  self.worker:kill()
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
    util.notify:send('E', { 'ERROR: Invalid search options; search aborted!\n', message })
    return
  end

  -- use defaults for missing arguments
  opts = opts or {}
  opts.directory = opts.directory or vim.loop.cwd()

  vim.ui.input({ prompt = 'Search pattern: ' }, function(pattern)
    if not pattern or #pattern == 0 then return end

    -- kill current job and reset buffer
    M.job:kill()
    buffer:reset()

    -- spawn a new job with the current pattern
    M.job:spawn(pattern, opts.directory)

    -- update the results floating window
    vim.api.nvim_win_set_buf(float.id, buffer.id)
    float:set_title((' Search Results: %s '):format(opts.directory))
  end)
end

return M
