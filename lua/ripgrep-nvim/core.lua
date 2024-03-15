---------------------------------------- CORE FUNCTIONALITY ----------------------------------------

local M = {}

---@class RipGrepNvimSearchJob
M.job = {
  ---@type vim.SystemObj? vim.system job handle (when active)
  handle = nil,
  ---@type string[] a list of results output by the job
  results = {},
}

---kills the job (when active) using SIGTERM
function M.job:kill()
  if self.handle then self.handle:kill 'SIGTERM' end
end

---clears old results and starts a new search job
---@param search_pattern string target search pattern
---@param directory string target directory to recursively search
function M.job:create(search_pattern, directory)
  self.results = {}

  -- constructs a search command
  local config_command = require('ripgrep-nvim.config').options.command
  local command = vim.deepcopy(config_command.args)
  table.insert(command, 1, config_command.exe)
  vim.list_extend(command, { search_pattern, directory })

  -- starts a new search process
  self.handle = vim.system(command, {
    stdout = function(err, data)
      if err then error(err) end -- backup to catch unexpected errors
      if not data then return end

      vim.list_extend(self.results, vim.split(data:gsub('\r\n', '\n'), '\n', { trimempty = true }))
    end,
  }, function() self.handle = nil end)
end

---@class RipGrepNvimSearchUI
M.ui = {}
---@class RipGrepNvimSearchUIBuffer
---@field id integer? results buffer number (if exists)
M.ui.buffer = {}
---@class RipGrepNvimSearchUIFloat
---@field id integer? results floating window number (if exists)
M.ui.float = {}

---temporarily unlocks and writes entries to the buffer
---@param lines string[] list of entries to write
---@param first integer? start of writing range (defaults to 0)
---@param last integer? end of writing range (defaults to -1)
function M.ui.buffer:write(lines, first, last)
  vim.bo[self.id].modifiable = true
  vim.api.nvim_buf_set_lines(self.id, first or 0, last or -1, true, lines)
  vim.bo[self.id].modifiable = false
end

M.ui.buffer = setmetatable(M.ui.buffer, {
  ---indexing metatable for buffer IDs
  ---@param self RipGrepNvimSearchUIBuffer
  ---@param field 'id' only this value is valid
  ---@return integer
  __index = function(self, field)
    if field ~= 'id' then return end

    self.id = vim.api.nvim_create_buf(false, true)

    vim.bo[self.id].buftype = 'nofile'
    vim.bo[self.id].modifiable = false

    vim.keymap.set('n', 'q', '<Cmd>quit<CR>', { buffer = self.id })

    vim.api.nvim_create_autocmd(
      'BufWipeout',
      { group = 'ripgrep_nvim', buffer = self.id, callback = function() self.id = nil end }
    )

    return self.id
  end,
})

---sets the floating window title
---@param title string title string
function M.ui.float:set_title(title)
  local config = vim.api.nvim_win_get_config(self.id)
  vim.api.nvim_win_set_config(self.id, vim.tbl_extend('force', config, { title = title }))
end

M.ui.float = setmetatable(M.ui.float, {
  ---indexing metatable for floating window IDs
  ---@param self RipGrepNvimSearchUIFloat
  ---@param field 'id' only this value is valid
  ---@return integer
  __index = function(self, field)
    if field ~= 'id' then return end

    local row, height, col, width = unpack(vim.tbl_flatten(vim.tbl_map(function(size)
      local c_size = size * 0.9
      local c_pos = (size - c_size) / 2 - 1
      return { math.floor(c_pos), math.floor(c_size) }
    end, { vim.o.lines, vim.o.columns })))
    self.id = vim.api.nvim_open_win(M.ui.buffer.id, true, {
      relative = 'editor',
      height = height,
      width = width,
      row = row,
      col = col,
      border = 'rounded',
      title = ' <uninitialized> ',
      title_pos = 'center',
    })

    vim.cmd [[ setlocal nospell cursorline nonumber statuscolumn= signcolumn=yes:1 ]]

    return self.id
  end,
})

---search for a custom string received from user input using specified search options
---@param opts RipGrepNvimSearchOptions? search options
function M.search(opts)
  opts = opts or {}
  opts.directory = opts.directory or vim.loop.cwd()

  -- kill existing job if any
  M.job:kill()

  -- clear previous search results
  M.ui.buffer:write { '-- No matches found --' }

  vim.ui.input({ prompt = 'Search pattern: ' }, function(pattern)
    if not pattern or #pattern == 0 then return end

    M.job:create(pattern, opts.directory)

    -- update the results floating window
    vim.api.nvim_win_set_buf(M.ui.float.id, M.ui.buffer.id)
    M.ui.float:set_title((' Search Results: %s '):format(opts.directory))

    -- write the search results
    M.job.handle:wait()
    if not vim.tbl_isempty(M.job.results) then M.ui.buffer:write(M.job.results) end
  end)
end

return M
