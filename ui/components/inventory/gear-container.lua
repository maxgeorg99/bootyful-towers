local Gear = require "gear"

---@class components.GearContainer : Element
---@field new fun(opts: ui.components.GearItem.Opts): components.GearContainer
---@field init fun(self: components.GearContainer, opts: ui.components.GearItem.Opts)
---@field name string
---@field container gear.Slottable
---@field gear gear.Gear
---@field background? vibes.Color
---@field on_drag_start fun(self: components.GearContainer, evt: ui.components.UIDragStartEvent)
---@field on_drag_end fun(self: components.GearContainer, evt: ui.components.UIDragEndEvent)
local GearContainer = class("ui.components.GearContainer", { super = Element })

---@class ui.components.GearItem.Opts
---@field name string
---@field gear gear.Gear
---@field background? number[]
---@field container gear.Slottable
---@field on_click? fun(self: components.GearContainer): UIAction
---@field on_drag_start fun(self: components.GearContainer, evt: ui.components.UIDragStartEvent)
---@field on_drag_end fun(self: components.GearContainer, evt: ui.components.UIDragEndEvent)
---@field z? number

function GearContainer:init(opts)
  validate(opts, {
    name = "string",
    gear = Gear,
    container = Element,
    background = Optional { "number[]" },
    on_click = Optional { "function" },
    z = Optional { "number" },
  })

  local x, y, w, h = opts.container:get_geo()
  Element.init(self, Box.new(Position.new(x, y), w, h), {
    z = opts.z or Z.GEAR_CONTAINER,
    interactable = true,
    draggable = true,
  })

  local ScaledImage = require "ui.components.scaled-img"
  self._on_drag_end = opts.on_drag_end
  self._on_drag_start = opts.on_drag_start
  self._on_click = opts.on_click

  self:append_child(ScaledImage.new {
    box = Box.new(Position.zero(), w, h),
    texture = opts.gear.texture,
    scale_style = "fit",
  })

  self.name = opts.name
  self.gear = opts.gear
  if opts.background then
    self.background = Color.new(unpack(opts.background))
    self.empty_background = Colors.gray:average(self.background, 0.8)
  else
    self.background = Colors.gray
    self.empty_background = Colors.gray
  end
end

function GearContainer:_render() end

function GearContainer:_click()
  if self._on_click then
    return self:_on_click()
  end
  return UIAction.HANDLED
end

function GearContainer:_drag_end(evt) self:_on_drag_end(evt) end

function GearContainer:_drag_start(evt)
  self:clear_animate()
  self:_on_drag_start(evt)
end

return GearContainer
