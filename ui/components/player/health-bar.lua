local BarGauge = require "ui.components.bar-gauge"
local ThreeSlice = require "ui.components.three-slice"

---@class (exact) ui.components.player.HealthBar : components.BarGauge
---@field new fun(box: ui.components.Box): ui.components.player.HealthBar
---@field init fun(self: ui.components.player.HealthBar, box: ui.components.Box)
local HealthBarElement =
  class("ui.components.player.HealthBar", { super = BarGauge })

---@param box ui.components.Box
function HealthBarElement:init(box)
  BarGauge.init(self, {
    box = box,
    color = { 1, 0, 0, 1 },
    get_current_value = function() return State.player.health end,
    get_maximum_value = function() return State.player.max_health end,
  })

  self.name = "HealthBarElement"
end

function HealthBarElement:update() end

--- Render the player health bar with overflow coloring
--- Red fills up to max (100). Any health above max is drawn in blue extending past the bar.
function HealthBarElement:_render()
  local x, y, w, h = self:get_geo()
  local padding = 2

  x = x + padding
  w = w - padding * 2

  local current = self.get_current_value()
  local maximum = self.get_maximum_value()

  local clamped = math.max(0, math.min(current, maximum))
  local overflow = math.max(0, current - maximum)

  -- Base (red) fill up to max
  local red_width = w * (clamped / maximum)
  love.graphics.setColor(Colors.dark_red)
  love.graphics.rectangle("fill", x, y, red_width, h)

  -- Overflow (blue) beyond max
  if overflow > 0 then
    local overflow_width = w * (overflow / maximum)
    love.graphics.setColor(Colors.blue)
    love.graphics.rectangle("fill", x + red_width, y, overflow_width, h)
  end

  -- Draw the three-slice frame over the fill
  love.graphics.setColor(1, 1, 1, 1)
  -- ThreeSlice._render(self)
end

return HealthBarElement
