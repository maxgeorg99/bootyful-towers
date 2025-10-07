local Projectile = require "vibes.projectile"
local Tower = require "vibes.tower.base"
local TowerUtils = require "vibes.tower.tower-utils"
local sprites = require("vibes.asset").sprites
local Hooks = require "vibes.hooks"
local TowerEvolutionOption = require "vibes.tower.meta.tower-evolution-option"
local TowerLevelUpReward = require "vibes.tower.meta.tower-levelup-reward"
local TowerUpgradeOption = require "vibes.tower.meta.tower-upgrade-option"

---@class vibes.WaterTower : vibes.Tower
---@field new fun()
---@field init fun(self: vibes.WaterTower)
---@field tower vibes.WaterTower
---@field knockback_multiplier number
---@field _base_stats tower.Stats
---@field _projectile_texture vibes.Texture
---@field _tags { archer: boolean, gun: boolean, magic: boolean }
local WaterTower = class("vibes.WaterTower", { super = Tower })

WaterTower._base_stats = TowerStats.new {
  range = Stat.new(3, 1), -- Close support range
  damage = Stat.new(8, 1), -- Less base damage than archer since it bypasses shields
  attack_speed = Stat.new(1.2, 1), -- Slightly slower than archer
  enemy_targets = Stat.new(1, 1), -- Targets one enemy
}

function WaterTower:init()
  Tower.init(
    self,
    self._base_stats:clone(),
    sprites.tower_water,
    { kind = TowerKind.SHOOTER, element_kind = ElementKind.WATER }
  )

  self.knockback_multiplier = 10
  self._projectile_texture = sprites.projectile_arrow
  self._tags = {
    archer = false,
    gun = false,
    magic = false,
  }
end

---@type table<TowerStatField, table<Rarity, tower.UpgradeOption>>
local base_enhancements = {
  [TowerStatField.DAMAGE] = TowerUtils.damage_by_list { 8, 12, 20, 40, 80 },
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
function WaterTower:get_tower_stat_enhancements() return base_enhancements end

---@return table<Rarity, tower.UpgradeOption[]>
function WaterTower:get_upgrade_options() return enhancements_by_rarity end

function WaterTower:get_levelup_reward()
  if self.level == 3 then
    return TowerLevelUpReward.new {
      kind = LevelUpRewardKind.EVOLVE_TOWER,
      reward = {
        TowerEvolutionOption.new {
          title = "Water Archer",
          tower_name = "Water Archer",
          texture = sprites.water_tower,
          description = {
            "A tower can apply 'Wet', which means block doesn't apply",
          },
          hints = {
            { field = TowerStatField.DAMAGE, hint = UpgradeHint.GOOD },
          },
          ---@param _evolution tower.EvolutionOption
          ---@param tower vibes.WaterTower
          on_accept = function(_evolution, tower) tower._tags.archer = true end,
        },
        TowerEvolutionOption.new {
          title = "Water Gun",
          tower_name = "Water Gun",
          texture = sprites.water_tower,
          description = {
            "Players get hit back X spaces based on Knockback",
          },
          hints = {
            { field = TowerStatField.RANGE, hint = UpgradeHint.GOOD },
          },
          ---@param _evolution tower.EvolutionOption
          ---@param tower vibes.WaterTower
          on_accept = function(_evolution, tower) tower._tags.gun = true end,
        },
        TowerEvolutionOption.new {
          title = "Water Magic",
          tower_name = "Water Magic",
          texture = sprites.water_tower,
          description = {
            "For every card played, Water tower increases by 1 that Level",
          },
          hints = {
            { field = TowerStatField.DAMAGE, hint = UpgradeHint.GOOD },
          },
          ---@param _evolution tower.EvolutionOption
          ---@param tower vibes.WaterTower
          on_accept = function(_evolution, tower)
            tower._tags.magic = true
            tower.hooks = Hooks.new {
              on_card_played = function(self, result)
                for _, tower in ipairs(State.towers) do
                  if tower._tags.archer then
                    local operations = {
                      TowerStatOperation.base_damage(1),
                    }
                    for _, operation in ipairs(operations) do
                      operation:apply_to_tower_stats(tower.stats_base)
                    end
                  end
                end
              end,
            }
          end,
        },
      },
    }
  elseif self.level == 5 and self._tags.archer then
    return TowerLevelUpReward.new {
      kind = LevelUpRewardKind.EVOLVE_TOWER,
      reward = {
        TowerEvolutionOption.new {
          title = "Water Archer+",
          tower_name = "Water Archer+",
          texture = sprites.water_tower,
          description = {
            "A tower can apply 'Wet', which means block doesn't apply",
          },
          hints = {
            { field = TowerStatField.DAMAGE, hint = UpgradeHint.GOOD },
          },
          ---@param _evolution tower.EvolutionOption
          ---@param tower vibes.WaterTower
          on_accept = function(_evolution, tower) tower._tags.archer = true end,
        },
      },
    }
  elseif self.level == 5 and self._tags.gun then
    return TowerLevelUpReward.new {
      kind = LevelUpRewardKind.EVOLVE_TOWER,
      reward = {
        TowerEvolutionOption.new {
          title = "Water Gun+",
          tower_name = "Water Gun+",
          texture = sprites.water_tower,
          description = {
            "Players get hit back X spaces based on Knockback",
          },
          hints = {
            { field = TowerStatField.RANGE, hint = UpgradeHint.GOOD },
          },
          ---@param _evolution tower.EvolutionOption
          ---@param tower vibes.WaterTower
          on_accept = function(_evolution, tower) tower._tags.gun = true end,
        },
      },
    }
  elseif self.level == 5 and self._tags.magic then
    return TowerLevelUpReward.new {
      kind = LevelUpRewardKind.EVOLVE_TOWER,
      reward = {
        TowerEvolutionOption.new {
          title = "Water Magic+",
          tower_name = "Water Magic+",
          texture = sprites.water_tower,
          description = {
            "For every card played, Water tower increases by 1 that Level",
          },
          hints = {
            { field = TowerStatField.DAMAGE, hint = UpgradeHint.GOOD },
          },
          ---@param _evolution tower.EvolutionOption
          ---@param tower vibes.WaterTower
          on_accept = function(_evolution, tower)
            tower._tags.magic = true
            tower.hooks = Hooks.new {
              on_card_played = function(self, result)
                for _, tower in ipairs(State.towers) do
                  if tower._tags.archer then
                    local operations = {
                      TowerStatOperation.base_damage(2),
                    }
                    for _, operation in ipairs(operations) do
                      operation:apply_to_tower_stats(tower.stats_base)
                    end
                  end
                end
              end,
            }
          end,
        },
      },
    }
  elseif self.level == 6 and self._tags.archer then
    return TowerLevelUpReward.new {
      kind = LevelUpRewardKind.EVOLVE_TOWER,
      reward = {
        TowerEvolutionOption.new {
          title = "Water Archer++",
          tower_name = "Water Archer++",
          texture = sprites.water_tower,
          description = {
            "A tower can apply 'Wet', which means block doesn't apply",
          },
          hints = {
            { field = TowerStatField.DAMAGE, hint = UpgradeHint.GOOD },
          },
          ---@param _evolution tower.EvolutionOption
          ---@param tower vibes.WaterTower
          on_accept = function(_evolution, tower) tower._tags.archer = true end,
        },
      },
    }
  elseif self.level == 6 and self._tags.gun then
    return TowerLevelUpReward.new {
      kind = LevelUpRewardKind.EVOLVE_TOWER,
      reward = {
        TowerEvolutionOption.new {
          title = "Water Gun++",
          tower_name = "Water Gun++",
          texture = sprites.water_tower,
          description = {
            "Players get hit back X spaces based on Knockback",
          },
          hints = {
            { field = TowerStatField.RANGE, hint = UpgradeHint.GOOD },
          },
          ---@param _evolution tower.EvolutionOption
          ---@param tower vibes.WaterTower
          on_accept = function(_evolution, tower) tower._tags.gun = true end,
        },
      },
    }
  elseif self.level == 6 and self._tags.magic then
    return TowerLevelUpReward.new {
      kind = LevelUpRewardKind.EVOLVE_TOWER,
      reward = {
        TowerEvolutionOption.new {
          title = "Water Magic++",
          tower_name = "Water Magic++",
          texture = sprites.water_tower,
          description = {
            "For every card played, Water tower increases by 1 that Level",
          },
          hints = {
            { field = TowerStatField.DAMAGE, hint = UpgradeHint.GOOD },
          },
          ---@param _evolution tower.EvolutionOption
          ---@param tower vibes.WaterTower
          on_accept = function(_evolution, tower)
            tower._tags.magic = true
            tower.hooks = Hooks.new {
              on_card_played = function(self, result)
                for _, tower in ipairs(State.towers) do
                  if tower._tags.archer then
                    local operations = {
                      TowerStatOperation.base_damage(3),
                    }
                    for _, operation in ipairs(operations) do
                      operation:apply_to_tower_stats(tower.stats_base)
                    end
                  end
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
function WaterTower:_create_projectile(initial_target)
  SoundManager:play_shoot_arrow(1.0) -- TODO: Create arrow shooting sound

  local enemy_position = initial_target.position:clone()
  local direction = enemy_position:sub(self.position)
  local dst =
    self.position:add(direction:normalize():scale(self:get_range_in_distance()))

  return Projectile.new {
    src = Position.from_cell(self.cell),
    dst = dst,
    speed = 12, -- Slightly faster than arrows
    durability = self:get_durability(),
    texture = self._projectile_texture,
    on_collide = function(_, enemy)
      local damage = self:get_damage()

      enemy.statuses.wet = true

      if self._tags.archer then
        local distance = self.position:distance(enemy.position)
        local range = self:get_range_in_distance()
        -- Bonus damage at close range (inverse of longbow)
        damage = damage * (1.5 - distance / range * 0.5)

        State:damage_enemy {
          source = self,
          enemy = enemy,
          damage = damage,
          kind = DamageKind.WATER,
        }
      end

      if self._tags.gun then
        enemy:knockback(
          Position.from_cell(self.cell)
            :sub(enemy.position)
            :normalize()
            :scale(self.knockback_multiplier * self.level - 1)
        )
        return
      end
    end,
  }
end

--- Create a projectile when attacking
---@param target vibes.Enemy
---@return vibes.Projectile?
function WaterTower:attack(target)
  if self._tags.magic then
    return nil
  end

  local projectile = self:_create_projectile(target)
  return projectile
end

return WaterTower
