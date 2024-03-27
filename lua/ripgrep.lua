------------------------------------------- RIPGREP.NVIM -------------------------------------------

local M = {}

---plugin setup function
---@param opts? RipgrepNvimUserOptions custom user options for plugin setup
function M.setup(opts) require('ripgrep-nvim.config').apply(opts) end

---search for a string in the current working directory
function M.search_cwd() require('ripgrep-nvim.core').search() end

---search for a string in the specified target directory
---@param target string path to the target directory
function M.search_dir(target) require('ripgrep-nvim.core').search { directory = target } end

return M
