---@diagnostic disable-next-line: duplicate-doc-alias
---@enum GearKind
local gear_kind = {
  HAT = "HAT",
  NECKLACE = "NECKLACE",
  RING = "RING",
  TOOL = "TOOL",
  SHIRT = "SHIRT",
  PANTS = "PANTS",
  SHOES = "SHOES",
}

---@diagnostic disable-next-line: duplicate-doc-alias
---@enum GearKind
return require("vibes.enum").new("GearKind", gear_kind)
