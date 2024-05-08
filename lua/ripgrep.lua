------------------------------------------- RIPGREP.NVIM -------------------------------------------

local M = {}

---plugin setup function
---@param opts? RipgrepNvimUserOptions custom user options for plugin setup
function M.setup(opts) require('ripgrep-nvim.config').apply(opts) end

---search for a custom string received from user input using specified search options
---@param opts? RipgrepNvimSearchOptions search options
local function search(opts)
  local state = require 'ripgrep-nvim.state'
  local handlers = require 'ripgrep-nvim.handlers'
  local ui = require 'ripgrep-nvim.ui'
  local util = require 'ripgrep-nvim.util'

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

  state.directory = opts.directory
  ui.open()
  handlers.start()
end

---search for a string in the current working directory
function M.search_cwd() search() end

---search for a string in the specified target directory
---@param target string path to the target directory
function M.search_dir(target) search { directory = target } end

return M
