local Object = require "vendor.object"

---@class vibes.Mouse
---@field _type "vibes.ui.Mouse"
---@field state vibes.MouseStates
local Mouse = Object.new "vibes.ui.Mouse"

---@enum vibes.MouseStates
local states = {
  UP = "UP",
  DOWN = "DOWN",
}

function Mouse.new()
  return setmetatable({
    _type = Mouse._type,
    state = states.UP,
  }, Mouse)
end

function Mouse:draw()
  -- Draw the cursor
  if self.state == "UP" then
    love.graphics.draw(
      Asset.sprites.cursor_up,
      State.mouse.x - 36 * 2,
      State.mouse.y - 36 * 2,
      0,
      2,
      2
    )
  elseif self.state == "DOWN" then
    love.graphics.draw(
      Asset.sprites.cursor_down,
      State.mouse.x - 36 * 2,
      State.mouse.y - 36 * 2,
      0,
      2,
      2
    )
  else
    love.graphics.draw(
      Asset.sprites.cursor_up,
      State.mouse.x - 36,
      State.mouse.y - 36
    )
  end

  if Config.debug.show_mouse_position then
    -- Write the position of the mouse
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(Asset.fonts.mono_12)

    love.graphics.print(
      tostring(State.mouse.x) .. ", " .. tostring(State.mouse.y),
      State.mouse.x - 10,
      State.mouse.y - 10
    )
  end
end

---@param dx number
---@param dy number
function Mouse:mousemoved(dx, dy) end

---@param button string
function Mouse:mousepressed(button)
  if button == 1 then
    self.state = states.DOWN
  end
end

---@param button string
function Mouse:mousereleased(button)
  if button == 1 then
    self.state = states.UP
  end
end

return Mouse
