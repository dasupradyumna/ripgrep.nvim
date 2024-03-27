----------------------------------------- UTILITY FUNCTIONS ----------------------------------------

local M = {}

---@class RipgrepNvimNotificationModule
M.notify = {
  ---@enum RipgrepNvimNotificationLevel
  level = {
    I = 'Normal', -- vim.log.levels.INFO,
    W = 'Warn', -- vim.log.levels.WARN,
    E = 'Error', -- vim.log.levels.ERROR,
  },
}

---echo a notification of the specified level
---@param level 'E' | 'I' | 'W' notification level
---@param message string[] notification message lines (can have format specifiers)
---@param ... any values to fill in format specifiers
-- TODO: support nvim-notify
function M.notify:send(level, message, ...)
  message[1] = '[ripgrep.nvim] ' .. message[1]
  vim.api.nvim_echo({ { table.concat(message, '\n'):format(...), self.level[level] } }, true, {})
end

---echo a notification of the specified level and throw a blank error
---@param ... any same arguments as M.notify:send()
function M.notify:throw(...)
  self:send(...)
  error()
end

---@alias RipgrepNvimValidateSpecification
---| { [1]: string, [2]: any[], [3]: string|string[]|fun(name: string, value: any): string? }

---validate the argument specifications
---@param specs RipgrepNvimValidateSpecification[] validation specification list
---@return string? # error message if validation fails, else `nil`
---@nodiscard
function M.validate_arguments(specs)
  for _, spec in ipairs(specs) do
    local name = spec[1] -- name of the parameter
    local value = spec[2] -- argument list in the same format as `vim.tbl_get` parameters
    if vim.tbl_count(value) == 1 then
      value = value[1] -- no indices provided
    else
      value = vim.tbl_get(unpack(value))
    end
    local checker = spec[3] -- validation checker

    local msg
    if type(checker) == 'function' then -- returns an error message only upon validation failure
      msg = checker(name, value)
    else -- returns an error message only if none of the valid types match
      if type(checker) == 'string' then checker = { checker } end

      msg = ('"%s" expected %s; got "%s" instead'):format(name, vim.inspect(checker), type(value))
      for _, check in ipairs(checker) do
        if type(value) == check then
          msg = nil
          break
        end
      end
    end

    if msg then return ('>> %s\n%s = %s'):format(msg, name, vim.inspect(value)) end
  end
end

return M
