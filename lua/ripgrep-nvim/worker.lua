---------------------------------------- ASYNCHRONOUS WORKER ---------------------------------------

---constructs a new instance of a worker
---@param callback fun(...: any)
---@return RipgrepNvimWorker
---@nodiscard
return function(callback)
  -- ensure that callback is callable
  if not vim.is_callable(callback) then
    error 'ripgrep.nvim: Worker constructor argument `callback` must be a callable object'
  end

  ---@class RipgrepNvimWorker
  local Worker = {}

  ---@class RipgrepNvimWorkerPrivate
  ---@field callback fun(...: any) work to be done by the worker
  ---@field jobs any[][] list of jobs for the worker to process
  ---@field lock boolean lock for critical sections in worker loop
  ---@field stop_when_no_jobs boolean whether to stop the worker when no jobs are available
  ---@field timer uv_timer_t internal timer for worker loop
  local __Worker = {
    callback = callback,
    jobs = {},
    lock = false,
    stop_when_no_jobs = false,
    timer = vim.loop.new_timer(),
  }

  ---add a new job to the worker
  ---@param ... any arguments for the callback
  function Worker:add(...) table.insert(__Worker.jobs, { ... }) end

  ---core job processing loop
  function __Worker.loop()
    -- regulate entry with the lock
    if __Worker.lock then return end
    __Worker.lock = true

    if vim.tbl_isempty(__Worker.jobs) then
      -- stop the timer if no jobs are available and worker has been stopped
      if __Worker.stop_when_no_jobs then
        __Worker.stop_when_no_jobs = false
        __Worker.timer:stop()
      end
      __Worker.lock = false
      return
    end

    -- schedule the callback with one job
    vim.schedule(function()
      __Worker.callback(unpack(table.remove(__Worker.jobs, 1)))
      __Worker.lock = false
    end)
  end

  ---start the worker and process jobs as they become available
  function Worker:start() __Worker.timer:start(0, 5, __Worker.loop) end

  ---stop the worker and end the loop after all existing jobs are processed
  function Worker:stop() __Worker.stop_when_no_jobs = true end

  ---clean up internal timer handle
  function Worker:close() __Worker.timer:close() end

  return Worker
end
