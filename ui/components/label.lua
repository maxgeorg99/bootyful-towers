--- @alias ui.components.Color number[]

---@class (exact) ui.components.Label : Element
---@field new fun(font: love.Font, text: string, color: ui.components.Color?, align: string?): ui.components.Label
---@field init fun(self: ui.components.Label, font: love.Font, text: string, color: ui.components.Color?, align: string?)
---@field super Element
---@field text string
---@field align string?
---@field font love.Font
---@field color ui.components.Color
local Label = class("ui.components.Label", { super = Element })

--- @param font love.Font
--- @param text string
--- @param color ui.components.Color?
--- @param align string?
function Label:init(font, text, color, align)
  Element.init(self, Box.empty())

  self.align = align or "left"
  self.font = font
  self.color = color or { 1, 1, 1 }
  self.name = "Label"
  self:set_text(text)
end

--- @param text string
function Label:set_text(text)
  self.text = text
  -- self:set_dim(self.font:getWidth(text), self.font:getHeight())
end

function Label:_render()
  local x, y, width = self:get_geo()
  love.graphics.setColor(
    self.color[1],
    self.color[2],
    self.color[3],
    self:get_opacity()
  )
  love.graphics.setFont(self.font)
  love.graphics.printf(self.text, x, y, width, self.align)
end

return Label
