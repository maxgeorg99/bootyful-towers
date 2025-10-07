local anim = require "vibes.anim"
local rectangle = require "utils.rectangle"

---@class Button.Props : Element.Props
---@field button_color number[]

---@class ui.components.Button : Element
---@field new fun(options: ui.components.Button.Opts): ui.components.Button
---@field init fun(self: ui.components.Button, options: ui.components.Button.Opts)
---@field on_click fun(): nil
---@field enter_time number?
---@field _draw_contents fun(self: ui.components.Button, x: number, y: number, width: number, height: number, opacity?:number): nil
---@field default_color vibes.Color
---@field hover_color vibes.Color
---@field inactive_color vibes.Color
---@field _props Button.Props
local Button = class("ui.components.Button", { super = Element })

---@class ui.components.Button.Opts
---@field box ui.components.Box
---@field draw (fun(...): nil)|string
---@field on_click fun(self: ui.components.Button): nil
---@field interactable boolean?
---@field z number?
---@field font love.Font?
---@field default_color vibes.Color?
---@field hover_color vibes.Color?
---@field inactive_color vibes.Color?

--- @param opts ui.components.Button.Opts
function Button:init(opts)
  local draw = opts.draw
  if type(draw) == "string" then
    opts.draw = Button.centered_text(draw, opts.font)
  end

  validate(opts, {
    box = Box,
    draw = "function",
    on_click = "function",
    background = "vibes.Color?",
    z = "number?",
  })

  Element.init(self, opts.box, {
    interactable = F.if_nil(opts.interactable, true),
    z = F.if_nil(opts.z, Z.BUTTON_DEFAULT),
  })

  self.default_color = opts.default_color or Colors.burgundy
  self.hover_color = opts.hover_color or Colors.dark_burgundy
  self.inactive_color = opts.inactive_color or Colors.gray

  self.targets.button_color = { unpack(self.default_color) }
  anim.extend(self.animator, {
    button_color = { initial = { unpack(self.default_color) }, rate = 1 },
  })

  local x, y = self:get_geo()

  self.name = string.format("Button(%d,%d)", x, y)
  self.on_click = opts.on_click

  -- We force to be function by this point.
  ---@diagnostic disable-next-line: assign-type-mismatch
  self._draw_contents = opts.draw
end

function Button:_update(dt)
  if self:is_focused() then
    self.targets.button_color = { unpack(self.hover_color) }
  elseif self:is_interactable() then
    self.targets.button_color = { unpack(self.default_color) }
  else
    self.targets.button_color = { unpack(self.inactive_color) }
  end
end

function Button:_render()
  love.graphics.push()

  local x, y, width, height = self:get_geo()
  local button_color = { unpack(self._props.button_color) }

  local opacity = self:get_opacity()
  button_color[4] = opacity

  local pressed_offset_y = 5
  local pressed_offset_x = 2

  -- Draw shadow slightly offset to bottom-left
  love.graphics.setColor(Colors.black:opacity(opacity * 0.3))
  love.graphics.rectangle(
    "fill",
    x - pressed_offset_x,
    y + pressed_offset_y,
    width,
    height,
    10,
    10,
    80
  )

  -- Draw main button
  local button_x, button_y =
    x + (1 - self._props.pressed) * pressed_offset_x,
    y + (self._props.pressed - 1) * pressed_offset_y

  love.graphics.setColor(button_color)
  love.graphics.rectangle("fill", button_x, button_y, width, height, 10, 10, 80)

  self:_draw_contents(button_x, button_y, width, height, opacity)

  -- Focus outline for keyboard focus/default selection
  if self:is_focused() then
    love.graphics.setLineWidth(3)
    love.graphics.setColor(Colors.yellow:opacity(opacity))
    love.graphics.rectangle(
      "line",
      button_x - 2,
      button_y - 2,
      width + 4,
      height + 4,
      12,
      12,
      80
    )
    love.graphics.setLineWidth(1)
    love.graphics.setColor(1, 1, 1, 1)
  end

  love.graphics.pop()
end

function Button:_click()
  self.on_click()
  return UIAction.HANDLED
end

---@param text string
---@param font? love.Font
---@return function
function Button.centered_text(text, font)
  return function(_, x, y, width, height, opacity)
    love.graphics.setFont(font or Asset.fonts.insignia_24)
    rectangle.center_text_in_rectangle(text, x, y, width, height, opacity)
  end
end

return Button
