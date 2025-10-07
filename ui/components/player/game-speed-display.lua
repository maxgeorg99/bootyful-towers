local Text = require "ui.components.text"

--- @class ui.components.player.GameSpeedDisplay : Element
--- @field new fun(opts: {box: ui.components.Box}): ui.components.player.GameSpeedDisplay
local GameSpeedDisplay =
  class("ui.components.player.GameSpeedDisplay", { super = Element })

function GameSpeedDisplay:init(opts)
  Element.init(self, opts.box)

  self.speed_text = Text.new {
    "1x",
    box = Box.new(Position.zero(), self:get_width(), self:get_height()),
    font = Asset.fonts.large,
    text_align = "right",
  }
  self:append_child(self.speed_text)

  -- Listen for game speed changes
  EventBus:listen_game_speed_changed(
    function(event) self:update_speed_display() end
  )
end

function GameSpeedDisplay:update_speed_display()
  local game_speed = SpeedManager:get_current_speed()
  local speed_text = tostring(game_speed) .. "x"
  self.speed_text.items[1] = speed_text
  self.speed_text:refresh()
end

function GameSpeedDisplay:update(dt) self:update_speed_display() end

function GameSpeedDisplay:_render()
  -- Custom rendering for game speed display
  local box = self:get_box()

  -- Background for the speed display
  love.graphics.setColor(0.1, 0.1, 0.1, 0.8)
  love.graphics.rectangle(
    "fill",
    box.position.x,
    box.position.y,
    box.width,
    box.height
  )

  -- Border
  love.graphics.setColor(0.3, 0.3, 0.3, 1)
  love.graphics.rectangle(
    "line",
    box.position.x,
    box.position.y,
    box.width,
    box.height
  )

  -- Children (text) are automatically rendered by the Element base class
end

return GameSpeedDisplay
