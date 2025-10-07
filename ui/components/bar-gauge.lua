local ThreeSlice = require "ui.components.three-slice"

---@class (exact) components.BarGauge : components.ThreeSlice
---@field new fun(opts: components.BarGauge.Opts): components.BarGauge
---@field init fun(self: components.BarGauge, opts: components.BarGauge.Opts)
---@field color number[]
---@field get_current_value (fun(): number)
---@field get_maximum_value (fun(): number)
local BarGauage = class("components.BarGauge", { super = ThreeSlice })

---@class components.BarGauge.Opts
---@field box ui.components.Box
---@field color? number[]
---@field get_current_value (fun(): number)
---@field get_maximum_value (fun(): number)

---@param opts components.BarGauge.Opts
function BarGauage:init(opts)
  opts.color = opts.color or { 0, 0, 0, 1 }

  validate(opts, {
    box = Box,
    color = "table",
    get_current_value = "function",
    get_maximum_value = "function",
  })

  ThreeSlice.init(self, {
    box = opts.box,
    image = Asset.sprites.player_health_bar_three_slice,
  })

  self.color = opts.color
  self.get_current_value = opts.get_current_value
  self.get_maximum_value = opts.get_maximum_value
end

function BarGauage:_render()
  -- Draw the rectangle fill
  local x, y, w, h = self:get_geo()
  local padding = 2

  x = x + padding
  w = w - padding * 2

  local fill_width = w * self.get_current_value() / (self.get_maximum_value())

  love.graphics.setColor(self.color)
  love.graphics.rectangle("fill", x, y, fill_width, h)

  -- Draw the three slice over the rectangle
  ThreeSlice._render(self)
end

return BarGauage
