local time = { frame = 0 }

local now = 0
local paused = false

---@return number
function time.now() return now end

---@param dt number
---@return number
function time.update(dt)
  time.dt = dt
  if paused then
    return 0
  end

  -- Apply game speed multiplier
  local game_speed = State.game_speed or 1
  if game_speed == 0 then
    -- Game is paused, don't advance time
    return 0
  end

  now = now + dt
  return dt
end

function time.pause() paused = true end
function time.resume() paused = false end
function time.gametime() return now - State.start_time end
function time._set_time(n) now = n end

return time
