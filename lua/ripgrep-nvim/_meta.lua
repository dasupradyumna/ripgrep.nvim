---------------------------------------- TYPE SPECIFICATIONS ---------------------------------------
---@meta _

--------------------------------- CONFIGURATION --------------------------------

---@class RipgrepNvimConfigCommand
---@field exe string path to the ripgrep executable
---@field args string[] command-line arguments to the ripgrep command

---@class RipgrepNvimConfig
---@field command RipgrepNvimConfigCommand ripgrep command specification
---@field format string regular expression to capture ripgrep output
---@field prefix string prompt buffer prefix string

--------------------------------- USER OPTIONS ---------------------------------

---@class RipgrepNvimUserOptionsCommand
---@field exe? string path to the ripgrep executable
---@field args? string[] command-line arguments to the ripgrep command

---@class RipgrepNvimUserOptions
---@field command? RipgrepNvimUserOptionsCommand ripgrep command specification
---@field format? string regular expression to capture ripgrep output
---@field prefix? string prompt buffer prefix string

------------------------------ SEARCH AND RESULTS ------------------------------

---@class RipgrepNvimSearchOptions
---@field directory? string path to the target directory for searching

---@class RipgrepNvimResultEntry
---@field file string filename with search match
---@field buffer integer buffer ID of filename (positive if already existing, negative otherwise)
---@field line integer line number of match in the matched buffer
