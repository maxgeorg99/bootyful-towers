local Projectile = require "vibes.projectile"
local Tower = require "vibes.tower.base"
local TowerUtils = require "vibes.tower.tower-utils"
local sprites = require("vibes.asset").sprites

local TowerEvolutionOption = require "vibes.tower.meta.tower-evolution-option"
local TowerLevelUpReward = require "vibes.tower.meta.tower-levelup-reward"
local TowerUpgradeOption = require "vibes.tower.meta.tower-upgrade-option"

local GameFunctions = require "vibes.data.game-functions"

---@class vibes.EmberWatchTower : vibes.Tower
---@field new fun()
---@field init fun(self: vibes.EmberWatchTower)
---@field tower vibes.EmberWatchTower
---@field _base_stats tower.Stats
---@field _projectile_texture vibes.Texture
local EmberWatchTower = class("vibes.EmberWatchTower", { super = Tower })

EmberWatchTower._base_stats = TowerStats.new {
  range = Stat.new(2.5, 1), -- Close-range focus
  damage = Stat.new(10, 1), -- Updated damage to 10
  attack_speed = Stat.new(1.5, 1), -- Attacks per second
  enemy_targets = Stat.new(1, 1), -- Targets one enemy
}

function EmberWatchTower:init()
  Tower.init(
    self,
    self._base_stats:clone(),
    sprites.tower_emberwatch,
    { kind = TowerKind.SHOOTER, element_kind = ElementKind.FIRE }
  )

  self.name = "Ember Watch"
  self.description = "Shoots fire arrows to burn enemies."

  self._tags = {
    inferno = false,
    scorch = false,
    sulfur = false,
  }

  self._projectile_texture = sprites.projectile_arrow
end

---@type table<TowerStatField, table<Rarity, tower.UpgradeOption>>
local base_enhancements = {
  [TowerStatField.DAMAGE] = TowerUtils.damage_by_list { 10, 15, 25, 50, 100 },
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

---@return table<TowerStatField, table<Rarity, tower.UpgradeOption>>
function EmberWatchTower:get_tower_stat_enhancements() return base_enhancements end

---@return table<Rarity, tower.UpgradeOption[]>
function EmberWatchTower:get_upgrade_options() return enhancements_by_rarity end

function EmberWatchTower:get_levelup_reward()
  if self.level == 3 then
    return TowerLevelUpReward.new {
      kind = LevelUpRewardKind.EVOLVE_TOWER,
      reward = {
        TowerEvolutionOption.new {
          title = "Scorch Upgrade",
          tower_name = "Scorch Tower",
          texture = sprites.tower_archer_longbow,
          description = {
            "Fire arrows spread flames to all nearby enemies on impact.",
            "Creates area-of-effect fire damage. Loses Range",
          },
          hints = {
            { field = TowerStatField.RANGE, hint = UpgradeHint.BAD },
            { field = TowerStatField.DAMAGE, hint = UpgradeHint.GOOD },
          },
          ---@param _evolution tower.EvolutionOption
          ---@param tower vibes.EmberWatchTower
          on_accept = function(_evolution, tower)
            tower._tags.scorch = true

            TowerStatOperation.mul_mult_range(0.75)
              :apply_to_tower_stats(tower.stats_base)
          end,
        },
        TowerEvolutionOption.new {
          title = "Inferno Upgrade",
          tower_name = "Inferno Tower",
          texture = sprites.tower_archer_longbow,
          description = {
            "Shoots slower but with intense flames that apply heavy fire stacks.",
            "Reduces {attack_speed:-90% attack speed} but increases fire damage.",
          },
          hints = {
            { field = TowerStatField.RANGE, hint = UpgradeHint.GOOD },
            { field = TowerStatField.DAMAGE, hint = UpgradeHint.BAD },
          },

          ---@param _evolution tower.EvolutionOption
          ---@param tower vibes.EmberWatchTower
          on_accept = function(_evolution, tower)
            tower._tags.inferno = true

            local operations = {
              TowerStatOperation.new {
                field = TowerStatField.ATTACK_SPEED,
                operation = StatOperation.new {
                  kind = StatOperationKind.MUL_MULT,
                  value = 0.1,
                },
              },
            }
            for _, operation in ipairs(operations) do
              operation:apply_to_tower_stats(tower.stats_base)
            end
          end,
        },
        TowerEvolutionOption.new {
          title = "Sulfur Upgrade",
          tower_name = "Sulfur Tower",
          texture = sprites.tower_archer_longbow,
          description = {
            "Creates persistent fire pools where enemies are hit.",
            "Fire pools continue burning enemies that walk through them.",
          },
          hints = {
            { field = TowerStatField.RANGE, hint = UpgradeHint.GOOD },
            { field = TowerStatField.DAMAGE, hint = UpgradeHint.BAD },
          },

          ---@param _evolution tower.EvolutionOption
          ---@param tower vibes.EmberWatchTower
          on_accept = function(_evolution, tower)
            tower._tags.sulfur = true
            self.stats_base.attack_speed = Stat.new(1, 1)
          end,
        },
      },
    }
  elseif self.level == 5 and self._tags.scorch then
    return TowerLevelUpReward.new {
      kind = LevelUpRewardKind.EVOLVE_TOWER,
      reward = {
        TowerEvolutionOption.new {
          title = "Scorch Upgrade",
          tower_name = "Scorch Tower+",
          texture = sprites.tower_archer_longbow,
          description = {
            "Enhanced area-of-effect fire spreading.",
            "Fire spreads even further to nearby enemies.",
          },
          hints = {
            { field = TowerStatField.RANGE, hint = UpgradeHint.GOOD },
            { field = TowerStatField.DAMAGE, hint = UpgradeHint.BAD },
          },

          ---@param _evolution tower.EvolutionOption
          ---@param tower vibes.EmberWatchTower
          on_accept = function(_evolution, tower) end,
        },
      },
    }
  elseif self.level == 5 and self._tags.inferno then
    return TowerLevelUpReward.new {
      kind = LevelUpRewardKind.EVOLVE_TOWER,
      reward = {
        TowerEvolutionOption.new {
          title = "Inferno Upgrade",
          tower_name = "Inferno Tower+",
          texture = sprites.tower_archer_longbow,
          description = {
            "Regains attack speed while maintaining intense fire damage.",
            "Adds {attack_speed:+1.5 attack speed} to compensate for earlier reduction.",
          },
          hints = {
            { field = TowerStatField.RANGE, hint = UpgradeHint.GOOD },
            { field = TowerStatField.DAMAGE, hint = UpgradeHint.BAD },
          },

          ---@param _evolution tower.EvolutionOption
          ---@param tower vibes.EmberWatchTower
          on_accept = function(_evolution, tower)
            local operations = { TowerStatOperation.base_attack_speed(1.5) }
            for _, operation in ipairs(operations) do
              operation:apply_to_tower_stats(tower.stats_base)
            end
          end,
        },
      },
    }
  elseif self.level == 5 and self._tags.sulfur then
    return TowerLevelUpReward.new {
      kind = LevelUpRewardKind.EVOLVE_TOWER,
      reward = {
        TowerEvolutionOption.new {
          title = "Sulfur Upgrade",
          tower_name = "Sulfur Tower+",
          texture = sprites.tower_archer_longbow,
          description = {
            "Enhanced fire pools with longer duration.",
            "Fire pools burn hotter and last longer.",
          },
          hints = {
            { field = TowerStatField.RANGE, hint = UpgradeHint.GOOD },
            { field = TowerStatField.DAMAGE, hint = UpgradeHint.BAD },
          },

          ---@param _evolution tower.EvolutionOption
          ---@param tower vibes.EmberWatchTower
          on_accept = function(_evolution, tower) end,
        },
      },
    }
  elseif self.level == 6 and self._tags.scorch then
    return TowerLevelUpReward.new {
      kind = LevelUpRewardKind.EVOLVE_TOWER,
      reward = {
        TowerEvolutionOption.new {
          title = "Scorch Upgrade",
          tower_name = "Scorch Tower++",
          texture = sprites.tower_archer_longbow,
          description = {
            "Maximum area-of-effect fire spreading with faster attacks.",
            "Adds {attack_speed:+1.0 attack speed} for rapid fire spreading.",
          },
          hints = {
            { field = TowerStatField.RANGE, hint = UpgradeHint.GOOD },
            { field = TowerStatField.DAMAGE, hint = UpgradeHint.BAD },
          },

          ---@param _evolution tower.EvolutionOption
          ---@param tower vibes.EmberWatchTower
          on_accept = function(_evolution, tower)
            local operations = {
              TowerStatOperation.base_attack_speed(1.0),
            }
            for _, operation in ipairs(operations) do
              operation:apply_to_tower_stats(tower.stats_base)
            end
          end,
        },
      },
    }
  elseif self.level == 6 and self._tags.inferno then
    return TowerLevelUpReward.new {
      kind = LevelUpRewardKind.EVOLVE_TOWER,
      reward = {
        TowerEvolutionOption.new {
          title = "Inferno Upgrade",
          tower_name = "Inferno Tower++",
          texture = sprites.tower_archer_longbow,
          description = {
            "Ultimate fire tower with maximum burning potential.",
            "Peak fire damage and stack application.",
          },
          hints = {
            { field = TowerStatField.RANGE, hint = UpgradeHint.GOOD },
            { field = TowerStatField.DAMAGE, hint = UpgradeHint.BAD },
          },

          ---@param _evolution tower.EvolutionOption
          ---@param tower vibes.EmberWatchTower
          on_accept = function(_evolution, tower) end,
        },
      },
    }
  elseif self.level == 6 and self._tags.sulfur then
    return TowerLevelUpReward.new {
      kind = LevelUpRewardKind.EVOLVE_TOWER,
      reward = {
        TowerEvolutionOption.new {
          title = "Sulfur Upgrade",
          tower_name = "Sulfur Tower++",
          texture = sprites.tower_archer_longbow,
          description = {
            "Ultimate fire pool creation with maximum coverage.",
            "Creates the most powerful and persistent fire pools. Lose 75% attack speed.",
          },
          hints = {
            { field = TowerStatField.RANGE, hint = UpgradeHint.GOOD },
            { field = TowerStatField.DAMAGE, hint = UpgradeHint.BAD },
          },

          ---@param _evolution tower.EvolutionOption
          ---@param tower vibes.EmberWatchTower
          on_accept = function(_evolution, tower)
            TowerStatOperation.mul_mult_attack_speed(0.25)
              :apply_to_tower_stats(tower.stats_base)
          end,
        },
      },
    }
  else
    return Tower.get_levelup_reward(self)
  end
end

function EmberWatchTower:_create_projectile(initial_target)
  -- TODO: Share this between the archer and longbow?
  SoundManager:play_shoot_arrow(1.5)

  if self._tags.inferno then
    return Projectile.new {
      src = Position.from_cell(self.cell),
      dst = initial_target.center,
      speed = 10,
      durability = 100,
      texture = sprites.projectile_fire,
      on_collide = function(_, enemy)
        enemy:apply_fire_stack(self, 10)

        -- Fire arrows do some base damage, so leave them in
        State:damage_enemy {
          source = self,
          enemy = enemy,
          damage = self:get_damage(),
          kind = DamageKind.FIRE,
        }
      end,
    }
  elseif self._tags.scorch then
    return Projectile.new {
      src = Position.from_cell(self.cell),
      dst = initial_target.center,
      speed = 10,
      durability = 100,
      texture = sprites.projectile_fire,
      on_collide = function(_, enemy)
        local enemies = GameFunctions.enemies_within(enemy.position, 100)
        for _, enemy in ipairs(enemies) do
          enemy:apply_fire_stack(self, 10)
        end

        enemy:apply_fire_stack(self, 10)

        -- Fire arrows do some base damage, so leave them in
        State:damage_enemy {
          source = self,
          enemy = enemy,
          damage = self:get_damage(),
          kind = DamageKind.FIRE,
        }
      end,
    }
  elseif self._tags.sulfur then
    return Projectile.new {
      src = Position.from_cell(self.cell),
      dst = initial_target.center,
      speed = 10,
      durability = 100,
      texture = sprites.projectile_fire,
      on_collide = function(_, enemy) FirePoolSystem:spawn_pool(enemy.position) end,
    }
  else
    local enemy_position = initial_target.center:clone()
    local direction = enemy_position:sub(self.position)
    local dst = enemy_position:add(
      direction:normalize():scale(self:get_range_in_distance())
    )

    return Projectile.new {
      src = Position.from_cell(self.cell),
      dst = dst,
      speed = function() return TrueRandom:decimal_range(10, 12) end,
      durability = self:get_durability(),
      texture = sprites.projectile_fire,
      fire = true,
      on_collide = function(_, enemy)
        enemy:apply_fire_stack(self, 4)

        State:damage_enemy {
          source = self,
          enemy = enemy,
          damage = self:get_damage(),
          kind = DamageKind.FIRE,
        }
      end,
    }
  end
end

--- Create a projectile when attacking
---@param target vibes.Enemy
---@return vibes.Projectile
function EmberWatchTower:attack(target) return self:_create_projectile(target) end

return EmberWatchTower
