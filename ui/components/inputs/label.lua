---@class (exact) ui.components.input.Label : Element
---@field new fun(options: ui.components.input.LabelOptions): ui.components.input.Label
---@field init fun(self: ui.components.input.Label, options: ui.components.input.LabelOptions)
---@field super Element
---@field text string
---@field on_click fun(): nil
---@field font love.Font
local Label = class("ui.components.input.Label", { super = Element })

---@class ui.components.input.LabelOptions
---@field box ui.components.Box
---@field text string
---@field interactable boolean?
---@field font? love.Font
---@field on_click fun(self: ui.components.input.Label): nil

--- @param options ui.components.input.LabelOptions
function Label:init(options)
  Element.init(self, options.box, {
    interactable = F.if_nil(options.interactable, true),
  })

  local x, y = self:get_geo()
  self.name = string.format("Label(%d,%d)", x, y)
  self.on_click = options.on_click
  self.text = options.text
  self.font = options.font

  if not self.font then
    self.font = Asset.fonts.insignia_16
  end
  local padding = 10
  self:set_width(self.font:getWidth(self.text) + (padding * 2))
end

function Label:_render()
  love.graphics.push()
  local x, y, width, height = self:get_geo()
  love.graphics.setFont(self.font)
  love.graphics.printf(
    self.text,
    x,
    y + ((height / 2) - (self.font:getHeight() / 2)),
    width,
    "center"
  )
  love.graphics.pop()
end

function Label:_update() end
function Label:focus() end
function Label:blur() end

function Label:_click()
  if self.on_click then
    return self:on_click()
  end
end

return Label
