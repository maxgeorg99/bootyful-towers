---@diagnostic disable-next-line: duplicate-doc-alias
---@enum EnemyStatus
local enemy_status = {
  ALIVE = "ALIVE",
  DEAD_FRFR = "DEAD_FRFR",
  REACHED_END = "REACHED_END",
}

---@diagnostic disable-next-line: duplicate-doc-alias
---@enum EnemyStatus
return require("vibes.enum").new("EnemyStatus", enemy_status)
