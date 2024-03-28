------------------------------------------- RIPGREP.NVIM -------------------------------------------

local ripgrep = require 'ripgrep'

----------------------------------- COMMANDS -----------------------------------

vim.api.nvim_create_user_command('RGSearch', ripgrep.search_cwd, {})
vim.api.nvim_create_user_command(
  'RGSearchDirectory',
  function(data) ripgrep.search_dir(data.args) end,
  { complete = 'dir', nargs = 1 }
)

--------------------------------- AUTOCOMMANDS ---------------------------------

vim.api.nvim_create_augroup('ripgrep_nvim', { clear = true })

vim.api.nvim_create_autocmd('WinClosed', {
  desc = 'Reset the cached floating window handles',
  group = 'ripgrep_nvim',
  callback = function(data)
    local float = require 'ripgrep-nvim.ui.float'
    if data.match == tostring(rawget(float, 'prompt')) then
      float.prompt = nil
    elseif data.match == tostring(rawget(float, 'results')) then
      float.results = nil
    end
    -- XXX: preview window
  end,
})
