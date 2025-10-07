---@diagnostic disable-next-line: duplicate-doc-alias
---@enum DamageKind
local damage_kind = {
  PHYSICAL = "PHYSICAL",
  FIRE = "FIRE",
  POISON = "POISON",
  WATER = "WATER",

  -- Special one-off damage kinds
  ORC_WHEELER_EXPLOSION = "ORC_WHEELER_EXPLOSION",
  ORCA_BOSS_EAT = "ORCA_BOSS_EAT",
}

---@diagnostic disable-next-line: duplicate-doc-alias
---@enum DamageKind
return require("vibes.enum").new("DamageKind", damage_kind)
