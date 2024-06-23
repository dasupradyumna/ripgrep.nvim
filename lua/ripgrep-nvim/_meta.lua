---------------------------------------- TYPE SPECIFICATIONS ---------------------------------------
---@meta _

--------------------------------- CONFIGURATION --------------------------------

---@class RipgrepNvimConfigCommand
---@field exe string path to the ripgrep executable
---@field args string[] command-line arguments to the ripgrep command

---@class RipgrepNvimConfigDebounce
---@field enable boolean whether to debounce changes to prompt
---@field timeout integer debounce timeout in milliseconds

---@class RipgrepNvimConfig
---@field command RipgrepNvimConfigCommand ripgrep command specification
---@field format string regular expression to capture ripgrep output
---@field prefix string prompt buffer prefix string
---@field debounce RipgrepNvimConfigDebounce debounce specification

--------------------------------- USER OPTIONS ---------------------------------

---@class RipgrepNvimUserOptionsCommand
---@field exe? string path to the ripgrep executable
---@field args? string[] command-line arguments to the ripgrep command

---@class RipgrepNvimUserOptionsDebounce
---@field enable? boolean whether to debounce changes to prompt
---@field timeout? integer debounce timeout in milliseconds (ignored when disabled)

---@class RipgrepNvimUserOptions
---@field command? RipgrepNvimUserOptionsCommand ripgrep command specification
---@field format? string regular expression to capture ripgrep output
---@field prefix? string prompt buffer prefix string
---@field debounce? RipgrepNvimUserOptionsDebounce debounce specification

------------------------------ SEARCH AND RESULTS ------------------------------

---@class RipgrepNvimSearchOptions
---@field directory? string path to the target directory for searching

---@class RipgrepNvimResultEntry
---@field file string filename with search match
---@field buffer integer buffer ID of filename (positive if already existing, negative otherwise)
---@field line integer line number of match in the matched buffer
