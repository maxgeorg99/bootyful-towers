-- Available game speeds, ordered from slowest to fastest
local SPEED_VALUES = { 1, 2, 4, 8 }

---@class vibes.SpeedManager
---@field new fun(): vibes.SpeedManager
---@field speeds number[]
local SpeedManager = class "vibes.SpeedManager"

function SpeedManager:init() self.speeds = SPEED_VALUES end

-- MAIN API: Use next_speed() for normal speed cycling
-- Other functions (set_speed, pause, resume, etc.) are for special/internal use cases

---Get the current game speed
---@return number
function SpeedManager:get_current_speed() return State.game_speed or 1 end

---Get the index of the current speed in the speeds array
---@return number
function SpeedManager:get_current_speed_index()
  local current_speed = self:get_current_speed()
  for i, speed in ipairs(self.speeds) do
    if speed == current_speed then
      return i
    end
  end
  -- Default to first speed if current speed not found
  return 1
end

---Advance to the next speed in sequence
---@return number The new speed
function SpeedManager:next_speed()
  local current_index = self:get_current_speed_index()
  local next_index = (current_index % #self.speeds) + 1
  local new_speed = self.speeds[next_index]

  self:set_speed(new_speed)
  return new_speed
end

---Cycle to the previous speed (internal/special use)
---@return number The new speed
function SpeedManager:cycle_to_previous_speed()
  local current_index = self:get_current_speed_index()
  local next_index = ((current_index - 2) % #self.speeds) + 1
  local new_speed = self.speeds[next_index]

  self:set_speed(new_speed)
  return new_speed
end

---Set the game speed directly (internal/special use)
---@param speed number The speed to set
---@param temp? boolean Whether to set the speed as the true speed
function SpeedManager:set_speed(speed, temp)
  if not temp then
    self._true_speed = speed
  end

  local old_speed = State.game_speed or 1
  State.game_speed = speed

  -- Emit event for speed change
  EventBus:emit_game_speed_changed {
    old_speed = old_speed,
    new_speed = speed,
  }

  logger.info("Game speed changed: %sx -> %sx", old_speed, speed)
end

---Reset speed to default (1x) - special use for game reset
function SpeedManager:reset_to_default() self:set_speed(1) end

---Pause the game (set speed to 0) - special use for pause functionality
function SpeedManager:pause() self:set_speed(0) end

---Resume the game (set speed to 1x) - special use for resume functionality
function SpeedManager:resume() self:set_speed(1) end

function SpeedManager:set_temp_speed(speed) self:set_speed(speed, true) end

function SpeedManager:restore_speed()
  if not self._true_speed then
    self._true_speed = 1
  end

  self:set_speed(self._true_speed)
end

return SpeedManager.new()
