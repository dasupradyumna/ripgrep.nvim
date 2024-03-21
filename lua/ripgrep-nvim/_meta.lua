---------------------------------------- TYPE SPECIFICATIONS ---------------------------------------
---@meta _

--------------------------------- CONFIGURATION --------------------------------

---@class RipgrepNvimConfigCommand
---@field exe string path to the ripgrep executable
---@field args string[] command-line arguments to the ripgrep command

---@class RipgrepNvimConfig
---@field command RipgrepNvimConfigCommand ripgrep command specification
---@field format string regular expression to capture ripgrep output

--------------------------------- USER OPTIONS ---------------------------------

---@class RipgrepNvimUserOptionsCommand
---@field exe? string path to the ripgrep executable
---@field args? string[] command-line arguments to the ripgrep command

---@class RipgrepNvimUserOptions
---@field command? RipgrepNvimUserOptionsCommand ripgrep command specification
---@field format? string regular expression to capture ripgrep output

-------------------------------- SEARCH OPTIONS --------------------------------

---@class RipgrepNvimSearchOptions
---@field directory? string path to the target directory for searching
