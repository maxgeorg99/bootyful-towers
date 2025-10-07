local Tower = require "vibes.tower.base"
local TowerUpgradeOption = require "vibes.tower.meta.tower-upgrade-option"
local TowerUtils = require "vibes.tower.tower-utils"

---@class vibes.TarTower : vibes.Tower
---@field new fun(): vibes.TarTower
---@field init fun(self: vibes.TarTower)
---@field _type "vibes.TarTower"
---@field operation enemy.StatOperation
local TarTower = class("vibes.TarTower", { super = Tower })

--- Tar Tower
function TarTower:init()
  local stats = TowerStats.new {
    range = Stat.new(2, 1),
    damage = Stat.new(0, 0),
    attack_speed = Stat.new(0, 0),
    crit_chance = Stat.new(0, 0),
    enemy_targets = Stat.new(0, 0),
  }
  local texture = Asset.sprites.tower_tar

  Tower.init(
    self,
    stats,
    texture,
    { kind = TowerKind.EFFECT, element_kind = ElementKind.PHYSICAL }
  )
  self.operation = EnemyStatOperation.new {
    field = EnemyStatField.SPEED,
    operation = StatOperation.new {
      kind = StatOperationKind.MUL_MULT,
      value = 0.5,
    },
  }
end

function TarTower:get_enemy_operations(_enemy) return { self.operation } end

---@type table<TowerStatField, table<Rarity, tower.UpgradeOption>>
local base_enhancements = {
  [TowerStatField.RANGE] = TowerUtils.range_by_list { 0.5, 0.75, 1.25, 2.5, 5.0 },
  [TowerStatField.ATTACK_SPEED] = TowerUtils.attack_speed_by_list {
    0.25,
    0.5,
    0.75,
    1.5,
    3.0,
  },
}

---@type table<Rarity, tower.UpgradeOption[]>
local enhancements_by_rarity =
  TowerUtils.convert_enhancement_by_type_to_rarity(base_enhancements)

local upgrades = {
  [Rarity.COMMON] = {
    TowerUpgradeOption.new {
      name = "Increase Range",
      rarity = Rarity.COMMON,
      operations = { TowerStatOperation.base_range(0.5) },
    },

    TowerUpgradeOption.new {
      name = "Stronger Slow",
      rarity = Rarity.COMMON,
      operations = { TowerStatOperation.base_damage(1) }, -- Could affect slow strength
    },
  },

  [Rarity.UNCOMMON] = {
    TowerUpgradeOption.new {
      name = "Range boost",
      rarity = Rarity.UNCOMMON,
      operations = {
        TowerStatOperation.base_range(0.5),
      },
    },

    TowerUpgradeOption.new {
      name = "Enhanced Tar",
      rarity = Rarity.UNCOMMON,
      operations = {
        TowerStatOperation.base_damage(2),
      },
    },
  },

  [Rarity.RARE] = {
    TowerUpgradeOption.new {
      name = "Wide Area Tar",
      rarity = Rarity.RARE,
      operations = {
        TowerStatOperation.base_range(1.0),
      },
    },

    TowerUpgradeOption.new {
      name = "Sticky Tar",
      rarity = Rarity.RARE,
      operations = {
        TowerStatOperation.base_damage(3),
      },
    },
  },

  [Rarity.EPIC] = {
    TowerUpgradeOption.new {
      name = "Balanced improvement",
      rarity = Rarity.EPIC,
      operations = {
        TowerStatOperation.base_range(0.5),
        TowerStatOperation.base_damage(2),
      },
    },

    TowerUpgradeOption.new {
      name = "Major Range boost",
      rarity = Rarity.EPIC,
      operations = {
        TowerStatOperation.base_range(1.5),
      },
    },
  },

  [Rarity.LEGENDARY] = {
    TowerUpgradeOption.new {
      name = "Ultimate Tar",
      rarity = Rarity.LEGENDARY,
      operations = {
        TowerStatOperation.base_range(2.0),
        TowerStatOperation.base_damage(5),
      },
    },
  },
}

---@return table<TowerStatField, table<Rarity, tower.UpgradeOption>>
function TarTower:get_tower_stat_enhancements() return base_enhancements end

---@return table<Rarity, tower.UpgradeOption[]>
function TarTower:get_upgrade_options() return enhancements_by_rarity end

return TarTower
