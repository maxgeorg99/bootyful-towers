---@diagnostic disable-next-line: duplicate-doc-alias
---@enum LevelUpRewardKind
local LevelUpRewardKind = {
  UPGRADE_TOWER = "UPGRADE_TOWER",
  EVOLVE_TOWER = "EVOLVE_TOWER",
}

---@diagnostic disable-next-line: duplicate-doc-alias
---@enum LevelUpRewardKind
return require("vibes.enum").new("LevelUpRewardKind", LevelUpRewardKind)
