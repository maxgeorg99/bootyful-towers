local Projectile = require "vibes.projectile"
local Tower = require "vibes.tower.base"
local TowerUtils = require "vibes.tower.tower-utils"
local sprites = require("vibes.asset").sprites
local Hooks = require "vibes.hooks"
local TowerEvolutionOption = require "vibes.tower.meta.tower-evolution-option"
local TowerLevelUpReward = require "vibes.tower.meta.tower-levelup-reward"
local TowerUpgradeOption = require "vibes.tower.meta.tower-upgrade-option"

---@class vibes.MoneyTower : vibes.Tower
---@field new fun()
---@field init fun(self: vibes.MoneyTower)
---@field tower vibes.MoneyTower
---@field element_kind ElementKind
---@field _base_stats tower.Stats
---@field _projectile_texture vibes.Texture
---@field _tags { }
---@field _kill_counter number
local MoneyTower = class("vibes.MoneyTower", { super = Tower })

MoneyTower._base_stats = TowerStats.new {
  range = Stat.new(0, 1), -- Slightly less range than archer
  damage = Stat.new(0, 1), -- Less base damage than archer since it bypasses shields
  attack_speed = Stat.new(0, 1), -- Slightly slower than archer
  enemy_targets = Stat.new(0, 1), -- Targets one enemy
}

function MoneyTower:init()
  Tower.init(
    self,
    self._base_stats:clone(),
    sprites.water_tower,
    { kind = TowerKind.EFFECT, element_kind = ElementKind.MONEY }
  )

  self._projectile_texture = sprites.projectile_arrow -- TODO: Create arrow projectile sprite
  self._tags = {}
  self._kill_counter = 0
  self.hooks = Hooks.new {
    after_enemy_death = function(self, enemy)
      self._kill_counter = self._kill_counter + 1
      if self._kill_counter >= 6 then
        print "Money Tower: 6 enemies died, giving 1 gold"
        State.player:gain_gold(1)
        self._kill_counter = 0
      end
    end,
  }
end

---@type table<TowerStatField, table<Rarity, tower.UpgradeOption>>
local base_enhancements = {
  [TowerStatField.DAMAGE] = TowerUtils.damage_by_list { 5, 8, 12, 25, 50 },
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
      name = "Increase Damage",
      rarity = Rarity.COMMON,
      operations = { TowerStatOperation.base_damage(10) },
    },

    TowerUpgradeOption.new {
      name = "Increase Attack Speed",
      rarity = Rarity.COMMON,
      operations = { TowerStatOperation.base_attack_speed(0.25) },
    },

    TowerUpgradeOption.new {
      name = "Increase Range",
      rarity = Rarity.COMMON,
      operations = { TowerStatOperation.base_range(0.5) },
    },
  },

  [Rarity.UNCOMMON] = {
    TowerUpgradeOption.new {
      name = "Mild damage & attack speed increase",
      rarity = Rarity.UNCOMMON,
      operations = {
        TowerStatOperation.base_damage(5),
        TowerStatOperation.base_attack_speed(0.125),
      },
    },

    TowerUpgradeOption.new {
      name = "Damage & range boost",
      rarity = Rarity.UNCOMMON,
      operations = {
        TowerStatOperation.base_damage(5),
        TowerStatOperation.base_range(0.25),
      },
    },

    TowerUpgradeOption.new {
      name = "Attack speed & range boost",
      rarity = Rarity.UNCOMMON,
      operations = {
        TowerStatOperation.base_attack_speed(0.125),
        TowerStatOperation.base_range(0.25),
      },
    },

    TowerUpgradeOption.new {
      name = "Critical boost",
      rarity = Rarity.UNCOMMON,
      operations = {
        TowerStatOperation.base_critical(0.02),
      },
    },
  },

  [Rarity.RARE] = {
    TowerUpgradeOption.new {
      name = "Damage & critical boost",
      rarity = Rarity.RARE,
      operations = {
        TowerStatOperation.base_damage(5),
        TowerStatOperation.base_critical(0.01),
      },
    },

    TowerUpgradeOption.new {
      name = "Range & critical boost",
      rarity = Rarity.RARE,
      operations = {
        TowerStatOperation.base_range(0.25),
        TowerStatOperation.base_critical(0.01),
      },
    },

    TowerUpgradeOption.new {
      name = "Attack speed & critical boost",
      rarity = Rarity.RARE,
      operations = {
        TowerStatOperation.base_attack_speed(0.125),
        TowerStatOperation.base_critical(0.01),
      },
    },
  },

  [Rarity.EPIC] = {
    TowerUpgradeOption.new {
      name = "Balanced improvement",
      rarity = Rarity.EPIC,
      operations = {
        TowerStatOperation.base_damage(3),
        TowerStatOperation.base_attack_speed(0.125),
        TowerStatOperation.base_range(0.25),
        TowerStatOperation.base_critical(0.01),
      },
    },

    TowerUpgradeOption.new {
      name = "Critical boost",
      rarity = Rarity.EPIC,
      operations = {
        TowerStatOperation.base_critical(0.04),
      },
    },
  },

  [Rarity.LEGENDARY] = {
    TowerUpgradeOption.new {
      name = "Critical boost",
      rarity = Rarity.LEGENDARY,
      operations = {
        TowerStatOperation.base_critical(0.08),
      },
    },
    TowerUpgradeOption.new {
      name = "Increase Durability",
      rarity = Rarity.LEGENDARY,
      operations = { TowerStatOperation.base_durability(1) },
    },
  },
}

---@return table<TowerStatField, table<Rarity, tower.UpgradeOption>>
function MoneyTower:get_tower_stat_enhancements() return base_enhancements end

---@return table<Rarity, tower.UpgradeOption[]>
function MoneyTower:get_upgrade_options() return enhancements_by_rarity end

function MoneyTower:get_levelup_reward()
  if self.level == 3 then
    return TowerLevelUpReward.new {
      kind = LevelUpRewardKind.EVOLVE_TOWER,
      reward = {
        TowerEvolutionOption.new {
          title = "Money Archer",
          tower_name = "Money Archer",
          texture = sprites.water_tower,
          description = {
            "A tower can apply 'Money', which means block doesn't apply",
          },
          hints = {
            { field = TowerStatField.DAMAGE, hint = UpgradeHint.GOOD },
          },
          ---@param _evolution tower.EvolutionOption
          ---@param tower vibes.MoneyTower
          on_accept = function(_evolution, tower)
            tower._kill_counter = 0
            tower.hooks = Hooks.new {
              after_enemy_death = function(self, enemy)
                self._kill_counter = self._kill_counter + 1
                if self._kill_counter >= 3 then
                  print "Money Archer: 3 enemies died, giving 1 gold"
                  State.player:gain_gold(1)
                  self._kill_counter = 0
                end
              end,
            }
          end,
        },
      },
    }
  elseif self.level == 5 then
    return TowerLevelUpReward.new {
      kind = LevelUpRewardKind.EVOLVE_TOWER,
      reward = {
        TowerEvolutionOption.new {
          title = "Money Archer+",
          tower_name = "Money Archer+",
          texture = sprites.water_tower,
          description = {
            "A tower can apply 'Money', which means block doesn't apply",
          },
          hints = {
            { field = TowerStatField.DAMAGE, hint = UpgradeHint.GOOD },
          },
          ---@param _evolution tower.EvolutionOption
          ---@param tower vibes.MoneyTower
          on_accept = function(_evolution, tower)
            tower._kill_counter = 0
            tower.hooks = Hooks.new {
              after_enemy_death = function(self, enemy)
                self._kill_counter = self._kill_counter + 1
                if self._kill_counter >= 2 then
                  print "Money Archer+: 2 enemies died, giving 1 gold (was 2)"
                  State.player:gain_gold(1)
                  self._kill_counter = 0
                end
              end,
            }
          end,
        },
      },
    }
  elseif self.level == 5 then
    return TowerLevelUpReward.new {
      kind = LevelUpRewardKind.EVOLVE_TOWER,
      reward = {
        TowerEvolutionOption.new {
          title = "Money Archer++",
          tower_name = "Money Archer++",
          texture = sprites.water_tower,
          description = {
            "Tower gives more money when an enemy dies",
          },
          hints = {
            { field = TowerStatField.DAMAGE, hint = UpgradeHint.GOOD },
          },
          ---@param _evolution tower.EvolutionOption
          ---@param tower vibes.MoneyTower
          on_accept = function(_evolution, tower)
            tower._kill_counter = 0
            tower.hooks = Hooks.new {
              after_enemy_death = function(self, enemy)
                self._kill_counter = self._kill_counter + 1
                if self._kill_counter >= 1 then
                  print "Money Archer++: 1 enemy died, giving 1 gold (was 3)"
                  State.player:gain_gold(1)
                  self._kill_counter = 0
                end
              end,
            }
          end,
        },
      },
    }
  else
    return Tower.get_levelup_reward(self)
  end
end

---@param initial_target vibes.Enemy
function MoneyTower:_create_projectile(initial_target) return nil end

--- Create a projectile when attacking
---@param target vibes.Enemy
---@return vibes.Projectile?
function MoneyTower:attack(target) return nil end

return MoneyTower
