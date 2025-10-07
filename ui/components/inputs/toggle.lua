local Label = require "ui.components.inputs.label"

local LABEL_W = 40
local LABEL_H = 40

--- @class ui.components.ToggleOption
--- @field label string
--- @field value string
--- @field _label_el? ui.components.input.Label

---@class (exact) ui.components.Toggle : Element
---@field new fun(opts: ui.components.Toggle.Opts): ui.components.Toggle
---@field init fun(self: ui.components.Toggle, opts: ui.components.Toggle.Opts)
---@field super Element
---@field value ui.components.ToggleOption
---@field options ui.components.ToggleOption[]
---@field on_click fun(): nil
---@field clickable boolean
local Toggle = class("ui.components.Toggle", { super = Element })

---@class ui.components.Toggle.Opts
---@field position vibes.Position
---@field options? ui.components.ToggleOption[]
---@field default_value? string
---@field on_click fun(self: ui.components.Toggle): nil
---@field clickable boolean

--- @param opts ui.components.Toggle.Opts
function Toggle:init(opts)
  local box = Box.new(opts.position, LABEL_W * 2, LABEL_H)
  Element.init(self, box, { interactable = true })

  local x, y, width, height = self:get_geo()
  self.name = string.format("Toggle(%d,%d)", x, y)
  self.z = 1
  self.on_click = opts.on_click

  self.options = opts.options
    or { { label = "on", value = "on" }, { label = "off", value = "off" } }

  self:_set_default_value(opts)

  local toggle_w = 0

  for _, option in ipairs(self.options) do
    local label = Label.new {
      text = option.label,
      box = Box.new(Position.new(toggle_w, 0), LABEL_W, LABEL_H),
      on_click = function(_) self.value = option end,
    }

    local _, _, label_w, _ = label:get_geo()
    toggle_w = toggle_w + label_w

    option._label_el = label

    self:append_child(option._label_el)
  end

  self:set_width(toggle_w)
end

function Toggle:_render()
  love.graphics.push()

  local x, y, width, height = self:get_geo()
  local rounded = 5
  love.graphics.setColor(Colors.slate:opacity(self:get_opacity()))
  love.graphics.rectangle("fill", x, y, width, height, rounded, rounded, 80)

  love.graphics.setColor(Colors.white:opacity(0.2 * self:get_opacity()))
  love.graphics.setLineWidth(2)
  love.graphics.rectangle("line", x, y, width, height)

  for _, option in ipairs(self.options) do
    local label = option._label_el
    if label then
      local label_x, _, label_w, _ = label:get_geo()
      if self.value == option then
        love.graphics.setColor(Colors.burgundy:opacity(self:get_opacity()))
        love.graphics.rectangle("fill", label_x, y, label_w, LABEL_H)
      end
      love.graphics.setColor(Colors.white:opacity(0.2 * self:get_opacity()))
      love.graphics.rectangle("line", label_x, y, label_w, LABEL_H)
    end
  end

  love.graphics.pop()
end

--- @param opts ui.components.Toggle.Opts
function Toggle:_set_default_value(opts)
  if #self.options > 0 then
    if opts.default_value ~= nil then
      for _, option in ipairs(self.options) do
        if option.value == opts.default_value then
          self.value = option
        end
      end
    else
      self.value = self.options[1]
    end
  end
end

function Toggle:_update() end
function Toggle:focus() end
function Toggle:blur() end

function Toggle:_click() self:on_click() end

return Toggle
