---@class (exact) elements.SpeedButton : Element
---@field new fun(opts: elements.SpeedButton.Opts): elements.SpeedButton
---@field init fun(self: elements.SpeedButton, opts: elements.SpeedButton.Opts)
---@field paused boolean
---@field pause_buttons vibes.Texture[]
---@field play_buttons vibes.Texture[]
---@field current_speed_index number
---@field _props elements.SpeedButton.Props
local SpeedButton = class("elements.SpeedButton", { super = Element })

---@class elements.SpeedButton.Props : Element.Props

---@class elements.SpeedButton.Opts
---@field position vibes.Position

local SCALE = 2

--- @param opts elements.SpeedButton.Opts
function SpeedButton:init(opts)
  validate(opts, {
    position = Position,
  })

  self.current_speed_index = SpeedManager:get_current_speed_index()

  local box = Box.new(opts.position, 58 * SCALE, 30 * SCALE)

  Element.init(self, box, { interactable = true, z = Z.GAME_UI })

  self.paused = false
  self.play_buttons = Asset.ui.speed_play_button
  self.pause_buttons = Asset.ui.speed_pause_button
end

function SpeedButton:_render()
  local pressed_offset_y = 8

  local x, y, _, h = self:get_geo()

  love.graphics.draw(Asset.ui.speed_button_bottom, x, y + h, 0, SCALE, SCALE)

  local button_y = y + self._props.pressed * pressed_offset_y

  if State.game_speed == 0 then
    love.graphics.draw(
      self.pause_buttons[self.current_speed_index],
      x,
      button_y,
      0,
      SCALE,
      SCALE
    )
  else
    love.graphics.draw(
      self.play_buttons[self.current_speed_index],
      x,
      button_y,
      0,
      SCALE,
      SCALE
    )
  end
end

function SpeedButton:_update()
  self.current_speed_index = SpeedManager:get_current_speed_index()
end

function SpeedButton:_click() SpeedManager:next_speed() end

function SpeedButton:_focus() end
function SpeedButton:_blur() end

return SpeedButton
