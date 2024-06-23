---------------------------------------- EXTERNAL SEARCH JOB ---------------------------------------

local config = require 'ripgrep-nvim.config'
local state = require 'ripgrep-nvim.state'

---@class RipgrepNvimSearchJob
---@field handle? vim.SystemObj vim.system job handle (when active)
---@field timer uv_timer_t debounce timer instance
local Job = {}

---spawns a new search job in given directory with the specified pattern
---@param pattern string target search pattern
---@param update fun(data: string[]) accepts update in the form of lines
local function spawn_ripgrep_job(pattern, update)
  -- constructs a search command
  local command = vim.deepcopy(config.options.command.args)
  table.insert(command, 1, config.options.command.exe)
  table.insert(command, pattern)
  table.insert(command, state.directory)

  local incomplete_entry
  Job.handle = vim.system(command, {
    stdout = function(err, data)
      if err then error(err) end -- backup to catch unexpected errors
      if not data then return end

      -- if 'data' does not end with a '\n', then preserve the last element for the next iteration
      local is_last_incomplete = not vim.endswith(data, '\n')
      if incomplete_entry then
        data = incomplete_entry .. data
        incomplete_entry = nil
      end
      data = vim.split(data:gsub('\r\n', '\n'), '\n', { trimempty = true })
      if is_last_incomplete then incomplete_entry = table.remove(data) end
      -- FIX: produces duplicate results when user types quickly
      --      (using an upvalue to job handle or implementing debounce)
      vim.defer_fn(function() update(data) end, 10)
    end,
  }, function() Job.handle = nil end)
end

---debounces (optionally) the spawning of ripgrep search job
---@param pattern string target search pattern
---@param update fun(data: string[]) accepts update in the form of lines
function Job:spawn_debounced(pattern, update)
  if self.timer:is_active() then self.timer:stop() end
  self.timer:start(
    config.options.debounce.timeout,
    0,
    function() spawn_ripgrep_job(pattern, update) end
  )
end

---kills the job (when active) using SIGTERM
function Job:kill()
  if self.handle then self.handle:kill 'SIGTERM' end
end

return Job
