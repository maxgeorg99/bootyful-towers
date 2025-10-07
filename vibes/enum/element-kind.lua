---@diagnostic disable-next-line: duplicate-doc-alias
---@enum ElementKind
local element_kind = {
  PHYSICAL = "PHYSICAL",
  WATER = "WATER",
  FIRE = "FIRE",
  POISON = "POISON",
  AIR = "AIR",
  EARTH = "EARTH",

  -- Special one-off elements
  MONEY = "MONEY",
  ZOMBIE = "ZOMBIE",
}

return require("vibes.enum").new("ElementKind", element_kind)
