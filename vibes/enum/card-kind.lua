---@diagnostic disable-next-line: duplicate-doc-alias
---@enum CardKind
local card_kind = {
  --- Towers are cards that are played and place a tower on the map.
  ---
  --- They contain a reference to the tower, which they hold and mutate
  --- as necessary, for applying experience, effects, etc.
  TOWER = "TOWER",

  --- Enhancements are cards that apply to a particular tower.
  ---
  --- They have a target and their own duration.
  --- Some are simple enhancements, like +10 range, +10 damage, etc
  --- Some are complex enhancements, like Lonely Tower
  ENHANCEMENT = "ENHANCEMENT",

  --- Auras are cards that are played with NO target.
  ---
  --- They have a duration and are applied to the map,
  --- and may have a variety of effects.
  AURA = "AURA",
}

---@diagnostic disable-next-line: duplicate-doc-alias
---@enum CardKind
return require("vibes.enum").new("CardKind", card_kind)
