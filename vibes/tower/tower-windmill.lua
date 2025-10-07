local Tower = require "vibes.tower.base"
local TowerUpgradeOption = require "vibes.tower.meta.tower-upgrade-option"
local TowerUtils = require "vibes.tower.tower-utils"

---@class vibes.TowerWindmill : vibes.Tower
---@field new fun(): vibes.TowerWindmill
local TowerWindmill = class("vibes.TowerWindmill", { super = Tower })

function TowerWindmill:init(opts)
  Tower.init(
    self,
    TowerStats.new {
      range = Stat.new(0, 1),
      damage = Stat.new(0, 1),
      attack_speed = Stat.new(0, 1),
      enemy_targets = Stat.new(0, 1),
    },
    Asset.sprites.tower_windmill or Asset.sprites.tower_archer,
    { kind = TowerKind.SUPPORT, element_kind = ElementKind.AIR }
  )

  self.animated_texture = Asset.sprites.tower_windmill_animated
end

function TowerWindmill:initial_experience() return 100 end

function TowerWindmill:is_supporting_tower(tower)
  local range = tower:get_range_in_distance()
  local distance = self.position:distance(tower.position)
  return distance <= range
end

---@param tower vibes.Tower
---@return tower.StatOperation[]
function TowerWindmill:get_support_tower_operations(tower)
  local operations = {
    TowerStatOperation.new {
      field = TowerStatField.RANGE,
      operation = StatOperation.new {
        kind = StatOperationKind.ADD_BASE,
        value = 1,
      },
    },
  }

  local enhancements = self.enhancements
  for _, enhancement in ipairs(enhancements) do
    if enhancement:is_active(tower) then
      local ops = enhancement:get_tower_operations(tower, 0)
      table.list_extend(operations, ops)
    end
  end

  return operations
end

--- Base enhancements for windmill tower focused on support capabilities
---@type table<TowerStatField, table<Rarity, tower.UpgradeOption>>
local base_enhancements = {
  [TowerStatField.RANGE] = TowerUtils.range_by_list { 1, 2, 3, 4, 5 },
}

---@type table<Rarity, tower.UpgradeOption[]>
local enhancements_by_rarity =
  TowerUtils.convert_enhancement_by_type_to_rarity(base_enhancements)

---@type table<Rarity, tower.UpgradeOption[]>
local special_enhancements = {
  [Rarity.LEGENDARY] = {
    TowerUpgradeOption.new {
      name = "Enhancement Amplifier",
      rarity = Rarity.LEGENDARY,
      description = "All enhancements applied to this tower are 50% more effective",
      operations = {}, -- This would need special handling in the support logic
    },
  },
}

---@return table<TowerStatField, table<Rarity, tower.UpgradeOption[]>>
function TowerWindmill:get_tower_stat_enhancements() return base_enhancements end

---@return table<Rarity, tower.UpgradeOption[]>
function TowerWindmill:get_upgrade_options()
  ---@type table<Rarity, tower.UpgradeOption[]>
  local upgrades = enhancements_by_rarity

  -- Add special enhancements
  for rarity, options in pairs(special_enhancements) do
    if not upgrades[rarity] then
      upgrades[rarity] = {}
    end
    for _, option in ipairs(options) do
      table.insert(upgrades[rarity], option)
    end
  end

  return upgrades
end

return TowerWindmill
