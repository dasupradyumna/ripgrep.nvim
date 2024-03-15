------------------------------------------- RIPGREP.NVIM -------------------------------------------

vim.api.nvim_create_augroup('ripgrep_nvim', { clear = true })

vim.api.nvim_create_autocmd('WinClosed', {
  desc = 'Reset the cached floating window handle',
  group = 'ripgrep_nvim',
  callback = function(data)
    local float = require('ripgrep-nvim.core').ui.float
    if data.match == tostring(rawget(float, 'id')) then float.id = nil end
  end,
})
