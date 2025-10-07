---@diagnostic disable-next-line: duplicate-doc-alias
---@enum PackKind
local pack_kind = {
  TOWER = "TOWER",
  MODIFIER = "MODIFIER",
  GEAR = "GEAR",
}

---@diagnostic disable-next-line: duplicate-doc-alias
---@enum PackKind
return require("vibes.enum").new("PackKind", pack_kind)
