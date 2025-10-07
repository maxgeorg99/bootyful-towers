---@diagnostic disable-next-line: duplicate-doc-alias
---@enum Rarity
local rarity = {
  COMMON = "COMMON",
  UNCOMMON = "UNCOMMON",
  RARE = "RARE",
  EPIC = "EPIC",
  LEGENDARY = "LEGENDARY",
}

return require("vibes.enum").new("Rarity", rarity)
