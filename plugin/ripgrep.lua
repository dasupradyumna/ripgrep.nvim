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
  desc = 'Stop search if any UI window is closed by external logic',
  group = 'ripgrep_nvim',
  callback = function(data)
    for _, winid in pairs(require('ripgrep-nvim.state').float) do
      if data.match == tostring(winid) then
        require('ripgrep-nvim.handlers').stop()
        return
      end
    end
  end,
})

-- create job handler timer instance when plugin is loaded
local job = require 'ripgrep-nvim.job'
job.timer = vim.uv.new_timer()
vim.api.nvim_create_autocmd('VimLeavePre', {
  desc = 'Close the job handler timer instance on exiting neovim',
  group = 'ripgrep_nvim',
  callback = function() job.timer:close() end,
})
