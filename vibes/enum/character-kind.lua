---@diagnostic disable-next-line: duplicate-doc-alias
---@enum CharacterKind
local character_kind = {
  BLACKSMITH = "vibes.characters.blacksmith",
  MAGE = "vibes.characters.mage",
  FUTURIST = "vibes.characters.futurist",
}

---@diagnostic disable-next-line: duplicate-doc-alias
---@enum CharacterKind
return require("vibes.enum").new(
  "CharacterKind",
  character_kind,
  { skip_value_check = true }
)
