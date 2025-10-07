---@diagnostic disable-next-line: duplicate-doc-alias
---@enum TowerKind
local tower_kind = {
  BASE = "BASE",
  SHOOTER = "SHOOTER",
  EFFECT = "EFFECT",
  DOT = "DOT",
  SUPPORT = "SUPPORT",
}

---@diagnostic disable-next-line: duplicate-doc-alias
---@enum TowerKind
return require("vibes.enum").new("TowerKind", tower_kind)
