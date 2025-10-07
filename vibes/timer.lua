-- timer.lua
local Timer = {}

local realtime_tasks = {}
local gametime_tasks = {}

--- Add a one-shot timer that triggers after the specified milliseconds in realtime
---@param ms number: milliseconds to wait
---@param fn function: function to call when timer expires
function Timer.oneshot(ms, fn)
  table.insert(realtime_tasks, {
    remain = ms / 1000, -- store seconds
    fn = fn,
  })
end

--- Add a one-shot timer that triggers after the specified milliseconds in gametime
---@param ms number: milliseconds to wait
---@param fn function: function to call when timer expires
function Timer.oneshot_gametime(ms, fn)
  table.insert(gametime_tasks, {
    remain = ms / 1000, -- store seconds
    fn = fn,
  })
end

--- Update realtime timers
---@param dt number: delta time in seconds
function Timer.update_realtime(dt)
  for i = #realtime_tasks, 1, -1 do
    local t = realtime_tasks[i]
    t.remain = t.remain - dt
    if t.remain <= 0 then
      t.fn()
      table.remove(realtime_tasks, i)
    end
  end
end

--- Update gametime timers
---@param dt number: delta time in seconds (will be multiplied by game speed)
function Timer.update_gametime(dt)
  for i = #gametime_tasks, 1, -1 do
    local t = gametime_tasks[i]
    t.remain = t.remain - dt
    if t.remain <= 0 then
      t.fn()
      table.remove(gametime_tasks, i)
    end
  end
end

-- Legacy alias - update realtime timers
function Timer.update(dt) Timer.update_realtime(dt) end

return Timer
