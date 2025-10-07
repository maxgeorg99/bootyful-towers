local Label = require "ui.components.inputs.label"

local LABEL_W = 40
local LABEL_H = 40

---@class (exact) ui.components.inputs.Range : Element
---@field new fun(opts: ui.components.inputs.Range.Opts): ui.components.inputs.Range
---@field init fun(self: ui.components.inputs.Range, opts: ui.components.inputs.Range.Opts)
---@field super Element
---@field value number
---@field max_value number
---@field min_value number
---@field increment_by number
---@field increment_btn ui.components.input.Label
---@field decrement_btn ui.components.input.Label
---@field on_click fun(): nil
---@field clickable boolean
---@field mouse_x number
local Range = class("ui.components.inputs.Range", { super = Element })

---@class ui.components.inputs.Range.Opts
---@field box ui.components.Box
---@field value number
---@field max_value number
---@field min_value? number
---@field increment_by? number
---@field on_click fun(self: ui.components.inputs.Range): nil
---@field clickable boolean

--- @param opts ui.components.inputs.Range.Opts
function Range:init(opts)
  Element.init(self, opts.box, { interactable = true })

  local x, y, width, height = self:get_geo()
  self.name = string.format("inputs.Range(%d,%d)", x, y)
  self.z = 1
  self.on_click = opts.on_click
  self.value = opts.value
  self.max_value = opts.max_value
  self.min_value = opts.min_value or 0
  self.increment_by = opts.increment_by or 1
  self.mouse_x = x

  assert(
    self.max_value % self.increment_by == 0,
    "inputs.Range increment_by option must be divisible by max_value"
  )
  local _, _, self_w, _ = self:get_geo()

  self.decrement_btn = Label.new {
    text = "<",
    box = Box.new(Position.new(0, 0), LABEL_W, LABEL_H),
    on_click = function(_) self:_decrement() end,
  }

  self.increment_btn = Label.new {
    text = ">",
    box = Box.new(Position.new(self_w - LABEL_W, 0), LABEL_W, LABEL_H),
    on_click = function(_) self:_increment() end,
  }

  self:append_child(self.decrement_btn)
  self:append_child(self.increment_btn)
end

function Range:_increment()
  local value = self.value + self.increment_by
  if value > self.max_value then
    return
  end
  self.value = value
  if self.on_click then
    self:on_click()
  end
end
function Range:_decrement()
  local value = self.value - self.increment_by
  if value < self.min_value then
    return
  end
  self.value = value
  if self.on_click then
    self:on_click()
  end
end

function Range:_render()
  love.graphics.push()
  local x, y, width, height = self:get_geo()
  local rounded = 5

  love.graphics.setColor(Colors.light_gray:opacity(self:get_opacity()))
  love.graphics.rectangle("fill", x, y, width, height, rounded, rounded, 80)

  love.graphics.setColor(Colors.gray:opacity(self:get_opacity()))
  love.graphics.setLineWidth(2)
  love.graphics.rectangle("line", x, y, width, height)

  love.graphics.setColor(Colors.white:opacity(0.5 * self:get_opacity()))
  love.graphics.rectangle(
    "fill",
    x + LABEL_W,
    y,
    width - (LABEL_W + LABEL_W),
    height
  )

  love.graphics.setColor(Colors.white:opacity(self:get_opacity()))

  love.graphics.rectangle(
    "fill",
    x + LABEL_W,
    y,
    self:_get_percent_width(),
    height
  )

  love.graphics.pop()
end

function Range:_get_percent()
  if self.max_value == 0 then
    return 0
  end
  return (self.value / self.max_value) * 100
end

function Range:_get_percent_width()
  local _, _, self_w, _ = self:get_geo()
  local width = (self.value / self.max_value) * (self_w - (LABEL_W + LABEL_W))
  return width
end

---@param evt ui.components.UIMouseEvent
---@param x number
---@param y number
function Range:mouse_moved(evt, x, y) self.mouse_x = x end

function Range:_update() end
function Range:focus() end
function Range:blur() end

function Range:_to_float()
  if self.max_value == 0 then
    return 0.0 -- Avoid division by zero
  end
  return self.value / self.max_value
end
function Range:_x_to_value()
  -- Calculate relative position within the element (0 to 1)
  local self_x, _, self_w, _ = self:get_geo()
  local relativeX = (self.mouse_x - self_x) / self_w

  -- Clamp to 0-1 range
  relativeX = math.max(0, math.min(1, relativeX))

  -- Map to your value range (1-10)
  local value = 0 + (relativeX * self.max_value - 0)

  -- Round to nearest integer
  return math.floor(value + 0.5)
end
function Range:_from_float(float_value) return float_value * self.max_value end
function Range:_click()
  local self_x, _, self_w, _ = self:get_geo()
  local x_start_offset = self_x + LABEL_W
  local x_end_offset = (self_x + self_w) - LABEL_W - 5

  if self.mouse_x > x_start_offset and self.mouse_x < x_end_offset then
    self.value = math.floor(self:_x_to_value() + 0.5)
  end

  return self:on_click()
end

return Range
