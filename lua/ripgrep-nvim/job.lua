---------------------------------------- CORE FUNCTIONALITY ----------------------------------------

---@class RipgrepNvimSearchJob
---@field handle? vim.SystemObj vim.system job handle (when active)
local Job = {}

---clears old results and starts a new search job
---@param search_pattern string target search pattern
---@param directory string target directory to recursively search
---@param update fun(data: string[]) accepts update in the form of lines
function Job:spawn(search_pattern, directory, update)
  -- constructs a search command
  -- TODO: extract into a command creator function
  local config_command = require('ripgrep-nvim.config').options.command
  local command = vim.deepcopy(config_command.args)
  table.insert(command, 1, config_command.exe)
  vim.list_extend(command, { search_pattern, directory })

  self.handle = vim.system(command, {
    stdout = function(err, data)
      if err then error(err) end -- backup to catch unexpected errors
      if not data then return end

      data = vim.split(data:gsub('\r\n', '\n'), '\n', { trimempty = true })
      -- FIX: produces duplicate results when user types quickly
      --      (using an upvalue to job handle or implementing debounce)
      vim.defer_fn(function() update(data) end, 10)
    end,
  }, function() self.handle = nil end)
end

---kills the job (when active) using SIGTERM
function Job:kill()
  if self.handle then self.handle:kill 'SIGTERM' end
end

return Job
