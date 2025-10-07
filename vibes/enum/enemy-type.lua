---@diagnostic disable-next-line: duplicate-doc-alias
---@enum EnemyType
local enemy_type = {
  -- Normal enemies
  BAT = "BAT",
  GOBLIN = "GOBLIN",
  MINE_GOBLIN = "MINE_GOBLIN",
  ORC = "ORC",
  WOLF = "WOLF",

  -- Mid level bosses
  BAT_ELITE = "BAT_ELITE",
  SNAIL = "SNAIL",
  ORC_CHIEF = "ORC_CHIEF",
  ORC_WHEELER = "ORC_WHEELER",
  ORC_SHAMAN = "ORC_SHAMAN",

  -- Bosses
  ORCA = "ORCA",
  WYVERN = "WYVERN",
  KING = "KING",
  CAT_TATUS = "CAT_TATUS",
  TAUNTOISE = "TAUNTOISE",
}

---@diagnostic disable-next-line: duplicate-doc-alias
---@enum EnemyType
return require("vibes.enum").new("EnemyType", enemy_type)
