---@class vibes.GearManager : vibes.Class
---@field new fun(opts: vibes.GearManager.Opts): vibes.GearManager
---@field init fun(self: self, opts: vibes.GearManager.Opts)
---@field _gear_slots table<GearSlot, gear.Gear>
local GearManager = class "vibes.GearManager"

---@class vibes.GearManager.Opts

---@param _opts vibes.GearManager.Opts
function GearManager:init(_opts)
  -- Initialize gear slots table
  self._gear_slots = {}
end

--- Set gear in a specific slot
---@param gear gear.Gear
---@param slot GearSlot
function GearManager:set_gear(gear, slot)
  -- Validate gear type for specific slots
  if slot == GearSlot.RING_LEFT or slot == GearSlot.RING_RIGHT then
    assert(gear.kind == GearKind.RING, "Ring slots require ring gear")
  elseif slot == GearSlot.TOOL_LEFT or slot == GearSlot.TOOL_RIGHT then
    assert(gear.kind == GearKind.TOOL, "Tool slots require tool gear")
  elseif slot == GearSlot.HAT then
    assert(gear.kind == GearKind.HAT, "Hat slot requires hat gear")
  elseif slot == GearSlot.SHIRT then
    assert(gear.kind == GearKind.SHIRT, "Shirt slot requires shirt gear")
  elseif slot == GearSlot.PANTS then
    assert(gear.kind == GearKind.PANTS, "Pants slot requires pants gear")
  elseif slot == GearSlot.SHOES then
    assert(gear.kind == GearKind.SHOES, "Shoes slot requires shoes gear")
  elseif slot == GearSlot.NECKLACE then
    assert(
      gear.kind == GearKind.NECKLACE,
      "Necklace slot requires necklace gear"
    )
    -- Inventory slots can accept any gear type
  end

  gear.slot = slot
  self._gear_slots[slot] = gear
end

--- Get gear from a specific slot
---@param slot GearSlot
---@return gear.Gear?
function GearManager:get_gear(slot) return self._gear_slots[slot] end

--- Remove gear from a specific slot
---@param slot GearSlot
function GearManager:remove_gear(slot)
  local gear = self._gear_slots[slot]
  if gear then
    gear.slot = nil
    self._gear_slots[slot] = nil
  end
end

-- Legacy setter methods for backward compatibility
function GearManager:set_hat(hat) self:set_gear(hat, GearSlot.HAT) end
function GearManager:set_shirt(shirt) self:set_gear(shirt, GearSlot.SHIRT) end
function GearManager:set_pants(pants) self:set_gear(pants, GearSlot.PANTS) end
function GearManager:set_shoes(shoes) self:set_gear(shoes, GearSlot.SHOES) end
function GearManager:set_necklace(necklace)
  self:set_gear(necklace, GearSlot.NECKLACE)
end
function GearManager:set_ring_left(ring) self:set_gear(ring, GearSlot.RING_LEFT) end
function GearManager:set_ring_right(ring)
  self:set_gear(ring, GearSlot.RING_RIGHT)
end
function GearManager:set_tool_left(tool) self:set_gear(tool, GearSlot.TOOL_LEFT) end
function GearManager:set_tool_right(tool)
  self:set_gear(tool, GearSlot.TOOL_RIGHT)
end
function GearManager:set_inventory_one(item)
  self:set_gear(item, GearSlot.INVENTORY_ONE)
end
function GearManager:set_inventory_two(item)
  self:set_gear(item, GearSlot.INVENTORY_TWO)
end
function GearManager:set_inventory_three(item)
  self:set_gear(item, GearSlot.INVENTORY_THREE)
end
function GearManager:set_inventory_four(item)
  self:set_gear(item, GearSlot.INVENTORY_FOUR)
end

---@return gear.Gear[]
function GearManager:get_active_gear()
  local gear = {}

  for _, gear_item in pairs(self._gear_slots) do
    table.insert(gear, gear_item)
  end

  return gear
end

---@param cb fun(gear: gear.Gear): nil
function GearManager:for_gear_in_active_gear(cb)
  for _, gear in ipairs(self:get_active_gear()) do
    cb(gear)
  end
end

--- Check if a specific gear is owned (in active slots or inventory)
---@param target_gear gear.Gear
---@return boolean
function GearManager:has_gear(target_gear)
  for slot, gear in pairs(self._gear_slots) do
    if gear == target_gear then
      return true
    end
  end
  return false
end

--- Assign gear to the specified slot
---@param gear gear.Gear
---@param gear_slot GearSlot
function GearManager:assign_gear_to_slot(gear, gear_slot)
  self:set_gear(gear, gear_slot)
  logger.info("Assigned gear '%s' to slot '%s'", gear.name, gear_slot)
end

return GearManager
