---@diagnostic disable-next-line: duplicate-doc-alias
---@enum TowerStatField
local stat_field = {
  CRITICAL = "critical",
  RANGE = "range",
  DAMAGE = "damage",
  ATTACK_SPEED = "attack_speed",
  ENEMY_TARGETS = "enemy_targets",
  AOE = "aoe",

  --- TODO: check
  -- NOT COMPLETELY IMPLEMENTED
  DURABILITY = "durability",
}

---@diagnostic disable-next-line: duplicate-doc-alias
---@enum TowerStatField
return require("vibes.enum").new(
  "TowerStatField",
  stat_field,
  { skip_value_check = true }
)
