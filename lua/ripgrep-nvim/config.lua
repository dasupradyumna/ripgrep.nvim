--------------------------------------- PLUGIN CONFIGURATION ---------------------------------------

local util = require 'ripgrep-nvim.util'

local M = {}

---@type RipgrepNvimConfig plugin default configuration
local defaults = {
  command = {
    exe = 'rg',
    args = {
      '--color=never',
      '--no-heading',
      '--line-number',
      '--smart-case',
      '--line-buffered',
      '--',
    },
  },
  format = '^(.+):(%d+):.+$',
  prefix = 'Pattern:',
  debounce = {
    enable = true,
    timeout = 200,
  },
}

---@type RipgrepNvimConfig currently active configuration
M.options = {} ---@diagnostic disable-line:missing-fields

---merge the custom user options with the plugin default configuration
---@param opts? RipgrepNvimUserOptions custom user options
function M.apply(opts)
  -- validate the user options
  local message = util.validate_arguments {
    {
      'opts',
      { opts },
      function(name, value)
        if type(value) == 'nil' then return end
        if type(value) ~= 'table' then
          return ('Setup options "%s" must be a table'):format(name)
        end

        local valid_fields = { 'command', 'format', 'prefix', 'debounce' }
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
    { 'opts.format', { opts, 'format' }, { 'string', 'nil' } },
    { 'opts.prefix', { opts, 'prefix' }, { 'string', 'nil' } },
    {
      'opts.command',
      { opts, 'command' },
      function(name, value)
        if type(value) == 'nil' then return end
        if type(value) ~= 'table' then return ('"%s" must be a table'):format(name) end

        local valid_fields = { 'exe', 'args' }
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
    { 'opts.command.exe', { opts, 'command', 'exe' }, { 'string', 'nil' } },
    {
      'opts.command.args',
      { opts, 'command', 'args' },
      function(name, value)
        if type(value) == 'nil' then return end
        local msg = ('"%s" must be a list of strings'):format(name)
        if vim.tbl_islist(value) then -- CHECK: does vim.islist() work?
          for _, v in ipairs(value) do
            if type(v) ~= 'string' then return msg end
          end
        else
          return msg
        end
      end,
    },
    {
      'opts.debounce',
      { opts, 'debounce' },
      function(name, value)
        if type(value) == 'nil' then return end
        if type(value) ~= 'table' then return ('"%s" must be a table'):format(name) end

        local valid_fields = { 'enable', 'timeout' }
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
    { 'opts.debounce.enable', { opts, 'debounce', 'enable' }, { 'boolean', 'nil' } },
    { 'opts.debounce.timeout', { opts, 'debounce', 'timeout' }, { 'integer', 'nil' } },
  }
  if message then
    local lines = { 'ERROR: User options could not be applied; setup failed!' }
    vim.list_extend(lines, vim.split(debug.traceback('', 2), '\n'), 2, 4)
    table.insert(lines, '\n' .. message)
    util.notify:send('E', lines)
    return
  end

  M.options = vim.tbl_deep_extend('force', defaults, opts)
end

return M
