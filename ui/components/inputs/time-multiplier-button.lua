local ButtonComponent = require "ui.components.inputs.button"

---@class ui.components.TimeMultiplierButton : ui.components.Button
---@field new fun(opts: ui.components.TimeMultiplierButton.Opts): ui.components.TimeMultiplierButton
---@field init fun(self: ui.components.TimeMultiplierButton, opts: ui.components.TimeMultiplierButton.Opts)
---@field on_speed_change fun(self: ui.components.TimeMultiplierButton, new_speed: number): nil
local TimeMultiplierButton =
  class("ui.components.TimeMultiplierButton", { super = ButtonComponent })

---@class ui.components.TimeMultiplierButton.Opts
---@field box ui.components.Box
---@field on_speed_change fun(self: ui.components.TimeMultiplierButton, new_speed: number): nil
---@field interactable boolean?
---@field font love.Font?
---@field color vibes.Color?
---@field hover_color vibes.Color?

function TimeMultiplierButton:init(opts)
  local draw_function = function(_, x, y, width, height, opacity)
    love.graphics.setFont(opts.font or Asset.fonts.insignia_24)
    love.graphics.setColor(1, 1, 1, opacity or 1)
    local current_speed = SpeedManager:get_current_speed()
    local text = string.format("Speed: %dx", current_speed)
    local text_width = (opts.font or Asset.fonts.insignia_24):getWidth(text)
    local text_height = (opts.font or Asset.fonts.insignia_24):getHeight()
    love.graphics.print(
      text,
      x + (width - text_width) / 2,
      y + (height - text_height) / 2
    )
  end

  local on_click = function()
    local new_speed = SpeedManager:next_speed()

    -- Call the callback if provided
    if self.on_speed_change then
      self:on_speed_change(new_speed)
    end
  end

  ButtonComponent.init(self, {
    box = opts.box,
    draw = draw_function,
    on_click = on_click,
    interactable = opts.interactable,
    font = opts.font,
    default_color = opts.color,
    hover_color = opts.hover_color,
  })

  self.on_speed_change = opts.on_speed_change
end

return TimeMultiplierButton
