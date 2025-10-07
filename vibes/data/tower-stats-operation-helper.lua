assert(
  Enum.length(TowerStatField) == 7,
  "enum.TowerStatField count has changed, Update tower.StatOperation!"
)

TowerStatFieldIcon = {
  [TowerStatField.CRITICAL] = IconType.CHANCE,
  [TowerStatField.DAMAGE] = IconType.DAMAGE,
  [TowerStatField.RANGE] = IconType.RANGE,
  [TowerStatField.ATTACK_SPEED] = IconType.ATTACKSPEED,
  [TowerStatField.ENEMY_TARGETS] = IconType.MULTI,
  [TowerStatField.AOE] = IconType.FIRE,
  [TowerStatField.DURABILITY] = IconType.DURABILITY,
}

TowerStatFieldLabel = {
  [TowerStatField.CRITICAL] = "Critical",
  [TowerStatField.DAMAGE] = "Damage",
  [TowerStatField.RANGE] = "Range",
  [TowerStatField.ATTACK_SPEED] = "Attack Speed",
  [TowerStatField.ENEMY_TARGETS] = "Enemy Targets",
  [TowerStatField.AOE] = "AOE",
  [TowerStatField.DURABILITY] = "Durability",
}

TowerStatFieldOrder = {
  TowerStatField.DAMAGE,
  TowerStatField.RANGE,
  TowerStatField.ATTACK_SPEED,
  TowerStatField.CRITICAL,
  TowerStatField.ENEMY_TARGETS,
  TowerStatField.AOE,
  TowerStatField.DURABILITY,
}
