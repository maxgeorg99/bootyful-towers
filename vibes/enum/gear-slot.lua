---@diagnostic disable-next-line: duplicate-doc-alias
---@enum GearSlot
local gear_slot = {
  HAT = "HAT",
  NECKLACE = "NECKLACE",
  RING_LEFT = "RING_LEFT",
  RING_RIGHT = "RING_RIGHT",
  TOOL_LEFT = "TOOL_LEFT",
  TOOL_RIGHT = "TOOL_RIGHT",
  SHIRT = "SHIRT",
  PANTS = "PANTS",
  SHOES = "SHOES",
  INVENTORY_ONE = "INVENTORY_ONE",
  INVENTORY_TWO = "INVENTORY_TWO",
  INVENTORY_THREE = "INVENTORY_THREE",
  INVENTORY_FOUR = "INVENTORY_FOUR",
}

---@diagnostic disable-next-line: duplicate-doc-alias
---@enum GearSlot
return require("vibes.enum").new("GearSlot", gear_slot)
