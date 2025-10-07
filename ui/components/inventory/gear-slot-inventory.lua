local Gear = require "gear"

---@class components.GearInventorySlot : Element
---@field new fun(opts: ui.components.GearInventorySlot.Opts): components.GearInventorySlot
---@field init fun(self: components.GearInventorySlot, opts: ui.components.GearInventorySlot.Opts)
---@field name string
---@field box ui.components.Box
---@field gear_slot GearSlot
---@field gear? gear.Gear
---@field background? vibes.Color
local GearSlotInventory =
  class("ui.components.GearInventorySlot", { super = Element })

---@class ui.components.GearInventorySlot.Opts
---@field name string
---@field box ui.components.Box
---@field gear_slot GearSlot
---@field gear? gear.Gear
---@field background number[]
---@field z? number

function GearSlotInventory:init(opts)
  validate(opts, {
    name = "string",
    box = Box,
    gear_slot = GearSlot,
    gear = Optional { Gear },
    background = Optional { "number[]" },
    z = Optional { "number" },
  })

  Element.init(self, opts.box, {
    z = opts.z,
  })

  self.name = opts.name
  self.gear = opts.gear
  self.gear_slot = opts.gear_slot
  -- Background colors no longer needed - using images instead
end

function GearSlotInventory:_render()
  local x, y, w, h = self:get_geo()
  local gear_slot_texture = require "vibes.gear-slot-texture"

  -- Get the appropriate slot texture
  local slot_texture = gear_slot_texture.get_slot_texture(self.gear_slot)

  -- Always draw the slot texture as placeholder/background
  -- Set opacity based on whether slot has gear or not
  if self.gear then
    love.graphics.setColor(1, 1, 1, 1) -- Full opacity when gear is present
  else
    love.graphics.setColor(1, 1, 1, 0.6) -- Slightly dimmed when empty, but still visible
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

function GearSlotInventory:can_assign_gear(gear) return true end

---@param gear gear.Gear
function GearSlotInventory:assign_gear(gear) self.gear = gear end
function GearSlotInventory:remove_gear() self.gear = nil end

function GearSlotInventory:_mark_selectable()
  self.border_color = Colors.can_select
end
function GearSlotInventory:_reset_selectable() self.border_color = nil end

return GearSlotInventory
