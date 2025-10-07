local Gear = require "gear"

---@class components.GearSlotBackground : Element
---@field new fun(opts: ui.components.GearSlotBackground.Opts): components.GearSlotBackground
---@field init fun(self: components.GearSlotBackground, opts: ui.components.GearSlotBackground.Opts)
---@field name string
---@field box ui.components.Box
---@field gear_kind GearKind
---@field gear_slot GearSlot
---@field gear? gear.Gear
---@field background? vibes.Color
local GearSlotBackground =
  class("ui.components.GearSlotBackground", { super = Element })

---@class ui.components.GearSlotBackground.Opts
---@field name string
---@field box ui.components.Box
---@field gear_kind GearKind
---@field gear_slot GearSlot
---@field gear? gear.Gear
---@field background number[]
---@field z? number

function GearSlotBackground:init(opts)
  validate(opts, {
    name = "string",
    box = Box,
    gear_kind = GearKind,
    gear_slot = GearSlot,
    gear = Optional { Gear },
    background = Optional { "number[]" },
    z = Optional { "number" },
  })

  Element.init(self, opts.box, {
    z = opts.z,
  })

  self.gear_kind = opts.gear_kind
  self.gear_slot = opts.gear_slot
  self.name = opts.name
  self.gear = opts.gear
  -- Background colors no longer needed - using images instead
end

function GearSlotBackground:_render()
  local x, y, w, h = self:get_geo()
  local gear_slot_texture = require "vibes.gear-slot-texture"

  -- Get the appropriate slot texture
  local slot_texture = gear_slot_texture.get_slot_texture(self.gear_slot)

  -- Set color based on whether slot has gear or not
  if self.gear then
    love.graphics.setColor(1, 1, 1, 1) -- Full opacity when gear is present
  else
    love.graphics.setColor(0.7, 0.7, 0.7, 0.8) -- Dimmed when empty
  end

  -- Draw the slot texture scaled to fit the slot
  -- love.graphics.draw(
  --   slot_texture,
  --   x,
  --   y,
  --   0,
  --   w / slot_texture:getWidth(),
  --   h / slot_texture:getHeight()
  -- )

  -- Reset color
  love.graphics.setColor(1, 1, 1, 1)

  if self.border_color then
    love.graphics.setColor(self.border_color:get())
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, w, h)
    love.graphics.setColor(1, 1, 1, 1)
  end
end

---@param gear gear.Gear
function GearSlotBackground:can_assign_gear(gear)
  return gear.kind == self.gear_kind
end

---@param gear gear.Gear
function GearSlotBackground:assign_gear(gear) self.gear = gear end
function GearSlotBackground:remove_gear() self.gear = nil end

function GearSlotBackground:_mark_selectable()
  self.border_color = Colors.can_select
end
function GearSlotBackground:_reset_selectable() self.border_color = nil end

return GearSlotBackground
