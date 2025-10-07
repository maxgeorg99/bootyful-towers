local TowerUpgradeOption = require "vibes.tower.meta.tower-upgrade-option"

---@param rarity Rarity
---@param value number
---@return tower.UpgradeOption
local function damage(rarity, value)
  return TowerUpgradeOption.new {
    name = string.format("Damage +%s", value),
    rarity = rarity,
    operations = { TowerStatOperation.base_damage(value) },
  }
end

---@param rarity Rarity
---@param value number
---@return tower.UpgradeOption
local function attack_speed(rarity, value)
  return TowerUpgradeOption.new {
    name = string.format("Attack Speed +%s", value),
    rarity = rarity,
    operations = { TowerStatOperation.base_attack_speed(value) },
  }
end

---@param rarity Rarity
---@param value number
---@return tower.UpgradeOption
local function range(rarity, value)
  return TowerUpgradeOption.new {
    name = string.format("Range +%s", value),
    rarity = rarity,
    operations = { TowerStatOperation.base_range(value) },
  }
end

---@param rarity Rarity
---@param value number
---@return tower.UpgradeOption
local function critical(rarity, value)
  return TowerUpgradeOption.new {
    name = string.format("Critical +%s", value),
    rarity = rarity,
    operations = { TowerStatOperation.base_critical(value) },
  }
end

---@param rarity Rarity
---@param value number
---@return tower.UpgradeOption
local function enemy_targets(rarity, value)
  return TowerUpgradeOption.new {
    name = string.format("Enemy Targets +%s", value),
    rarity = rarity,
    operations = { TowerStatOperation.base_enemy_targets(value) },
  }
end

---@param type TowerStatField
---@return fun(rarity: Rarity, value: number): tower.UpgradeOption
local function type_fn_select(type)
  if type == TowerStatField.DAMAGE then
    return damage
  elseif type == TowerStatField.ATTACK_SPEED then
    return attack_speed
  elseif type == TowerStatField.RANGE then
    return range
  elseif type == TowerStatField.CRITICAL then
    return critical
  elseif type == TowerStatField.ENEMY_TARGETS then
    return enemy_targets
  end
  return function() assert(false) end
end

---@param t TowerStatField
---@return fun(values: number[]): tower.UpgradeOption[]
local function stat_set(t)
  local type_fn = type_fn_select(t)
  return function(values)
    assert(type(values) == "table", "values must be a table")
    assert(#values == 5, "values must have 5 elements")
    return {
      [Rarity.COMMON] = type_fn(Rarity.COMMON, values[1]),
      [Rarity.UNCOMMON] = type_fn(Rarity.UNCOMMON, values[2]),
      [Rarity.RARE] = type_fn(Rarity.RARE, values[3]),
      [Rarity.EPIC] = type_fn(Rarity.EPIC, values[4]),
      [Rarity.LEGENDARY] = type_fn(Rarity.LEGENDARY, values[5]),
    }
  end
end

---@param enhancement_by_type table<TowerStatField, table<Rarity, tower.UpgradeOption[]>>
local function stat_set_by_rarity(enhancement_by_type)
  local rarity_enhancement_by_type = {}
  for _, rarities in pairs(enhancement_by_type) do
    for rarity, operations in pairs(rarities) do
      rarity_enhancement_by_type[rarity] = rarity_enhancement_by_type[rarity]
        or {}
      table.insert(rarity_enhancement_by_type[rarity], operations)
    end
  end
  return rarity_enhancement_by_type
end

---@param tower vibes.Tower
local get_operation_by_kind = function(tower, rarity, kind)
  local enhancements = tower:get_tower_stat_enhancements()
  if not enhancements then
    return {}
  end

  local damages = enhancements[kind]
  if not damages then
    return {}
  end

  local operation = damages[rarity]
  if not operation then
    return {}
  end

  return operation.operations
end

return {
  damage = damage,
  attack_speed = attack_speed,
  range = range,
  critical = critical,
  enemy_targets = enemy_targets,
  damage_by_list = stat_set(TowerStatField.DAMAGE),
  attack_speed_by_list = stat_set(TowerStatField.ATTACK_SPEED),
  range_by_list = stat_set(TowerStatField.RANGE),
  critical_by_list = stat_set(TowerStatField.CRITICAL),
  enemy_targets_by_list = stat_set(TowerStatField.ENEMY_TARGETS),
  convert_enhancement_by_type_to_rarity = stat_set_by_rarity,
  get_operation_by_kind = get_operation_by_kind,
}
