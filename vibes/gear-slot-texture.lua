--- Get the texture for a specific gear slot
---@param slot GearSlot
---@return vibes.Texture
local get_slot_texture = function(slot)
  local assets = require "vibes.asset"

  if slot == GearSlot.HAT then
    return assets.sprites.gear_slot_helmet
  elseif slot == GearSlot.NECKLACE then
    return assets.sprites.gear_slot_necklace
  elseif slot == GearSlot.RING_LEFT then
    return assets.sprites.gear_slot_ring_left
  elseif slot == GearSlot.RING_RIGHT then
    return assets.sprites.gear_slot_ring_right
  elseif slot == GearSlot.TOOL_LEFT then
    return assets.sprites.gear_slot_tool_left
  elseif slot == GearSlot.TOOL_RIGHT then
    return assets.sprites.gear_slot_tool_right
  elseif slot == GearSlot.SHIRT then
    return assets.sprites.gear_slot_shirt
  elseif slot == GearSlot.PANTS then
    return assets.sprites.gear_slot_pants
  elseif slot == GearSlot.SHOES then
    return assets.sprites.gear_slot_shoes
  elseif
    slot == GearSlot.INVENTORY_ONE
    or slot == GearSlot.INVENTORY_TWO
    or slot == GearSlot.INVENTORY_THREE
    or slot == GearSlot.INVENTORY_FOUR
  then
    return assets.sprites.inventory_slot
  else
    -- Fallback to inventory slot for unknown slots
    return assets.sprites.inventory_slot
  end
end

return {
  get_slot_texture = get_slot_texture,
}
