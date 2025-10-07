---@diagnostic disable-next-line: duplicate-doc-alias
---@enum EnemyStatField
local stat_field = {
  SPEED = "speed",
  DAMAGE = "damage",
  SHIELD = "shield",
  SHIELD_CAPACITY = "shield_capacity",
}

---@diagnostic disable-next-line: duplicate-doc-alias
---@enum EnemyStatField
return require("vibes.enum").new(
  "EnemyStatField",
  stat_field,
  { skip_value_check = true }
)
