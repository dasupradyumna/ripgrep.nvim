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

----------------------------------- LIBUV API ----------------------------------

---@diagnostic disable:inject-field

---returns the current working directory
---@return string
---@nodiscard
function vim.loop.cwd() end

---creates and returns a new timer instance
---@return uv_timer_t
function vim.loop.new_timer() end

---@class uv_timer_t
local uv_timer_t = {}

---start the current timer with the given specification
---@param timeout_ms integer initial timeout (in ms)
---@param repeat_ms integer repeat time (in ms)
---@param callback function function that is called repeatedly
function uv_timer_t:start(timeout_ms, repeat_ms, callback) end

---stop the timer and cancel callback loop
function uv_timer_t:stop() end

---close the timer and free its handle
function uv_timer_t:close() end
