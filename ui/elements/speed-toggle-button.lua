---@class (exact) elements.SpeedToggleButton : Element
---@field new fun(opts: elements.SpeedToggleButton.Opts): elements.SpeedToggleButton
---@field init fun(self: elements.SpeedToggleButton, opts: elements.SpeedToggleButton.Opts)
---@field paused boolean
---@field previous_speed number
---@field pause_button vibes.Texture
---@field play_button vibes.Texture
---@field callback fun(pause:boolean)
---@field _props elements.SpeedToggleButton.Props
local SpeedToggleButton =
  class("elements.SpeedToggleButton", { super = Element })

---@class elements.SpeedToggleButton.Props : Element.Props

---@class elements.SpeedToggleButton.Opts
---@field position vibes.Position
---@field callback fun(pause:boolean)

local SCALE = 2

--- @param opts elements.SpeedToggleButton.Opts
function SpeedToggleButton:init(opts)
  validate(opts, {
    position = Position,
    callback = "function?",
  })

  self.callback = opts.callback

  local box = Box.new(opts.position, 32 * SCALE, 30 * SCALE)

  Element.init(self, box, { interactable = true, z = Z.GAME_UI })
  self.paused = false
  self.play_button = Asset.ui.speed_toggle_button.play
  self.pause_button = Asset.ui.speed_toggle_button.pause
  self.previous_speed = SpeedManager:get_current_speed()
end

function SpeedToggleButton:_render()
  local pressed_offset_y = 8

  local x, y, w, h = self:get_geo()

  self:with_color(
    Colors.button_brown,
    function()
      love.graphics.rectangle(
        "fill",
        x,
        y + pressed_offset_y,
        w,
        h - pressed_offset_y + (4 * SCALE)
      )
    end
  )

  local button_y = y + self._props.pressed * pressed_offset_y

  if self.paused then
    love.graphics.draw(self.pause_button, x, button_y, 0, SCALE, SCALE)
  else
    love.graphics.draw(self.play_button, x, button_y, 0, SCALE, SCALE)
  end
end

function SpeedToggleButton:_update()
  self.paused = SpeedManager:get_current_speed() == 0
end

function SpeedToggleButton:_click()
  self.paused = not self.paused
  if self.paused then
    self.previous_speed = SpeedManager:get_current_speed()
    SpeedManager:pause()
  else
    SpeedManager:set_speed(self.previous_speed)
  end
  self.callback(self.paused)
end
function SpeedToggleButton:_focus() end
function SpeedToggleButton:_blur() end

return SpeedToggleButton
