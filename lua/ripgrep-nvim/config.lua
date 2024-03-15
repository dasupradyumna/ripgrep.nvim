--------------------------------------- PLUGIN CONFIGURATION ---------------------------------------

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
}

---@type RipgrepNvimConfig currently active configuration
M.options = {} ---@diagnostic disable-line:missing-fields

---merge the custom user options with the plugin default configuration
---@param user_opts RipgrepNvimUserOptions custom user options
function M.apply(user_opts)
  -- TODO: validate `user_opts`
  M.options = vim.tbl_deep_extend('force', defaults, user_opts)
end

return M
