---------------------------------------- TYPE SPECIFICATIONS ---------------------------------------
---@meta

--------------------------------- CONFIGURATION --------------------------------

---@class RipGrepNvimConfigCommand
---@field exe string path to the ripgrep executable
---@field args string[] command-line arguments to the ripgrep command

---@class RipGrepNvimConfig
---@field command RipGrepNvimConfigCommand ripgrep command specification
---@field format string regular expression to capture ripgrep output

--------------------------------- USER OPTIONS ---------------------------------

---@class RipGrepNvimUserOptionsCommand
---@field exe? string path to the ripgrep executable
---@field args? string[] command-line arguments to the ripgrep command

---@class RipGrepNvimUserOptions
---@field command? RipGrepNvimUserOptionsCommand ripgrep command specification
---@field format? string regular expression to capture ripgrep output

-------------------------------- SEARCH OPTIONS --------------------------------

---@class RipGrepNvimSearchOptions
---@field directory? string path to the target directory for searching

----------------------------------- LIBUV API ----------------------------------

---@diagnostic disable:inject-field

---returns the current working directory
---@return string
---@nodiscard
function vim.loop.cwd() end
