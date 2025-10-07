local GameFunctions = require "vibes.data.game-functions"
local Projectile = require "vibes.projectile"
local Tower = require "vibes.tower.base"
local TowerUtils = require "vibes.tower.tower-utils"
local sprites = require("vibes.asset").sprites

local TowerEvolutionOption = require "vibes.tower.meta.tower-evolution-option"
local TowerLevelUpReward = require "vibes.tower.meta.tower-levelup-reward"
local TowerUpgradeOption = require "vibes.tower.meta.tower-upgrade-option"

-- TODO: We have a ballista tower, could be one of the upgrades. We have assets
-- for that already to go.
-- self.texture = sprites.tower_ballista_loaded
-- self.texture = sprites.tower_ballista_shoot

---@class vibes.CatapaultTower : vibes.Tower
---@field new fun(): vibes.CatapaultTower
---@field init fun(self: vibes.CatapaultTower)
---@field projectiles vibes.Projectile[]
---@field cell vibes.Cell
---@field _tags { cannon: boolean, trebuchet: boolean, bombard: boolean }
local CatapaultTower = class("vibes.CatapaultTower", { super = Tower })

--- Creates a new CatapaultTower
function CatapaultTower:init()
  Tower.init(
    self,
    TowerStats.new {
      range = Stat.new(6, 1), -- Long siege range (reduced from 8)
      damage = Stat.new(25, 1), -- Moderate damage (reduced from 50)
      attack_speed = Stat.new(0.2, 1), -- Slower attack speed (reduced from 0.25)
      enemy_targets = Stat.new(1, 1), -- Catapault can only target one enemy
      aoe = Stat.new(1.5, 1), -- AOE of the explosion (reduced from 2)
    },
    Asset.sprites.tower_catapault_loaded,
    { kind = TowerKind.SHOOTER, element_kind = ElementKind.PHYSICAL }
  )

  self._tags = {
    cannon = false,
    trebuchet = false,
    bombard = false,
  }
end

function CatapaultTower:update(dt)
  local current_time = TIME.now()
  local time_since_last_attack = current_time
    - (self.state.last_attack_time or 0)
  local attack_cooldown = 1 / self:get_attack_speed()

  -- Use trebuchet textures if evolved to trebuchet
  if self._tags.trebuchet then
    if time_since_last_attack >= attack_cooldown * 0.9 then
      self.texture = Asset.sprites.tower_trebuchet_loaded
    else
      self.texture = Asset.sprites.tower_trebuchet_shoot
    end
  else
    -- Use catapult textures for base tower and other evolutions
    if time_since_last_attack >= attack_cooldown * 0.9 then
      self.texture = Asset.sprites.tower_catapault_loaded
    else
      self.texture = Asset.sprites.tower_catapault_shoot
    end
  end

  Tower.update(self, dt)
end

function CatapaultTower:get_projectile_starting_position()
  return Position.from_cell(self.cell)
    :add(Position.new(0, -Config.grid.cell_size * 0.5))
end

---@type table<TowerStatField, table<Rarity, tower.UpgradeOption>>
local base_enhancements = {
  [TowerStatField.DAMAGE] = TowerUtils.damage_by_list { 4, 6, 9, 15, 25 },
  [TowerStatField.RANGE] = TowerUtils.range_by_list {
    0.15,
    0.25,
    0.4,
    0.75,
    1.25,
  },
  [TowerStatField.ATTACK_SPEED] = TowerUtils.attack_speed_by_list {
    0.05,
    0.075,
    0.125,
    0.25,
    0.5,
  },
}

---@type table<Rarity, tower.UpgradeOption[]>
local enhancements_by_rarity =
  TowerUtils.convert_enhancement_by_type_to_rarity(base_enhancements)

function CatapaultTower:get_levelup_reward()
  if self.level == 3 then
    return TowerLevelUpReward.new {
      kind = LevelUpRewardKind.EVOLVE_TOWER,
      reward = {
        TowerEvolutionOption.new {
          title = "Cannon Tower",
          tower_name = "Cannon Tower",
          texture = sprites.tower_catapault_loaded, -- TODO: Add cannon sprite
          description = {
            "Faster attack speed and increased range. ",
            "Sacrifices some damage for speed. ",
          },
          hints = {
            { field = TowerStatField.ATTACK_SPEED, hint = UpgradeHint.GOOD },
            { field = TowerStatField.RANGE, hint = UpgradeHint.GOOD },
          },
          on_accept = function(_evolution, tower)
            ---@cast tower vibes.CatapaultTower
            tower._tags.cannon = true
            -- Increase attack speed and range, reduce damage slightly
            local operations = {
              TowerStatOperation.base_attack_speed(0.15), -- Faster
              TowerStatOperation.base_range(1), -- Longer range
              TowerStatOperation.base_damage(-5), -- Less damage
            }
            for _, operation in ipairs(operations) do
              operation:apply_to_tower_stats(tower.stats_base)
            end
          end,
        },
        TowerEvolutionOption.new {
          title = "Trebuchet Tower",
          tower_name = "Trebuchet Tower",
          texture = sprites.tower_trebuchet,
          description = {
            "Massive range and damage increase. ",
            "Even slower attack speed but devastating impact. ",
          },
          hints = {
            { field = TowerStatField.RANGE, hint = UpgradeHint.GOOD },
            { field = TowerStatField.DAMAGE, hint = UpgradeHint.GOOD },
            { field = TowerStatField.ATTACK_SPEED, hint = UpgradeHint.BAD },
          },
          on_accept = function(_evolution, tower)
            ---@cast tower vibes.CatapaultTower
            tower._tags.trebuchet = true
            -- Massive range and damage, slower attack speed
            local operations = {
              TowerStatOperation.base_range(2), -- Much longer range
              TowerStatOperation.base_damage(20), -- More damage
              TowerStatOperation.base_attack_speed(-0.05), -- Slower
              TowerStatOperation.base_aoe(0.5), -- Larger explosion
            }
            for _, operation in ipairs(operations) do
              operation:apply_to_tower_stats(tower.stats_base)
            end
          end,
        },
        TowerEvolutionOption.new {
          title = "Bombard Tower",
          tower_name = "Bombard Tower",
          texture = sprites.tower_catapault_loaded, -- TODO: Add bombard sprite
          description = {
            "Massive area of effect damage. ",
            "Specializes in clearing groups of enemies. ",
          },
          hints = {
            { field = TowerStatField.AOE, hint = UpgradeHint.GOOD },
            { field = TowerStatField.DAMAGE, hint = UpgradeHint.GOOD },
          },
          on_accept = function(_evolution, tower)
            ---@cast tower vibes.CatapaultTower
            tower._tags.bombard = true
            -- Focus on AOE and damage
            local operations = {
              TowerStatOperation.base_aoe(1), -- Much larger explosion
              TowerStatOperation.base_damage(10), -- More damage
              TowerStatOperation.base_range(0.5), -- Slightly more range
            }
            for _, operation in ipairs(operations) do
              operation:apply_to_tower_stats(tower.stats_base)
            end
          end,
        },
      },
    }
  elseif self.level == 5 and self._tags.cannon then
    return TowerLevelUpReward.new {
      kind = LevelUpRewardKind.EVOLVE_TOWER,
      reward = {
        TowerEvolutionOption.new {
          title = "Cannon Tower+",
          tower_name = "Cannon Tower+",
          texture = sprites.tower_catapault_loaded,
          description = {
            "Further improved attack speed and range. ",
            "Rapid-fire siege weapon. ",
          },
          hints = {
            { field = TowerStatField.ATTACK_SPEED, hint = UpgradeHint.GOOD },
            { field = TowerStatField.RANGE, hint = UpgradeHint.GOOD },
          },
          on_accept = function(_evolution, tower)
            local operations = {
              TowerStatOperation.base_attack_speed(0.08),
              TowerStatOperation.base_range(0.5),
            }
            for _, operation in ipairs(operations) do
              operation:apply_to_tower_stats(tower.stats_base)
            end
          end,
        },
      },
    }
  elseif self.level == 5 and self._tags.trebuchet then
    return TowerLevelUpReward.new {
      kind = LevelUpRewardKind.EVOLVE_TOWER,
      reward = {
        TowerEvolutionOption.new {
          title = "Trebuchet Tower+",
          tower_name = "Trebuchet Tower+",
          texture = sprites.tower_trebuchet,
          description = {
            "Unmatched range and devastating damage. ",
            "The ultimate long-range siege weapon. ",
          },
          hints = {
            { field = TowerStatField.RANGE, hint = UpgradeHint.GOOD },
            { field = TowerStatField.DAMAGE, hint = UpgradeHint.GOOD },
          },
          on_accept = function(_evolution, tower)
            local operations = {
              TowerStatOperation.base_range(1.5),
              TowerStatOperation.base_damage(15),
              TowerStatOperation.base_aoe(0.3),
            }
            for _, operation in ipairs(operations) do
              operation:apply_to_tower_stats(tower.stats_base)
            end
          end,
        },
      },
    }
  elseif self.level == 5 and self._tags.bombard then
    return TowerLevelUpReward.new {
      kind = LevelUpRewardKind.EVOLVE_TOWER,
      reward = {
        TowerEvolutionOption.new {
          title = "Bombard Tower+",
          tower_name = "Bombard Tower+",
          texture = sprites.tower_catapault_loaded,
          description = {
            "Massive explosions that clear entire groups. ",
            "Area denial specialist. ",
          },
          hints = {
            { field = TowerStatField.AOE, hint = UpgradeHint.GOOD },
            { field = TowerStatField.DAMAGE, hint = UpgradeHint.GOOD },
          },
          on_accept = function(_evolution, tower)
            local operations = {
              TowerStatOperation.base_aoe(0.8),
              TowerStatOperation.base_damage(8),
            }
            for _, operation in ipairs(operations) do
              operation:apply_to_tower_stats(tower.stats_base)
            end
          end,
        },
      },
    }
  elseif self.level == 6 and self._tags.cannon then
    return TowerLevelUpReward.new {
      kind = LevelUpRewardKind.EVOLVE_TOWER,
      reward = {
        TowerEvolutionOption.new {
          title = "Cannon Tower++",
          tower_name = "Cannon Tower++",
          texture = sprites.tower_catapault_loaded,
          description = {
            "Maximum rate of fire achieved. ",
            "Continuous barrage capability. ",
          },
          hints = {
            { field = TowerStatField.ATTACK_SPEED, hint = UpgradeHint.GOOD },
          },
          on_accept = function(_evolution, tower)
            local operations = {
              TowerStatOperation.base_attack_speed(0.1),
              TowerStatOperation.base_range(0.5),
            }
            for _, operation in ipairs(operations) do
              operation:apply_to_tower_stats(tower.stats_base)
            end
          end,
        },
      },
    }
  elseif self.level == 6 and self._tags.trebuchet then
    return TowerLevelUpReward.new {
      kind = LevelUpRewardKind.EVOLVE_TOWER,
      reward = {
        TowerEvolutionOption.new {
          title = "Trebuchet Tower++",
          tower_name = "Trebuchet Tower++",
          texture = sprites.tower_trebuchet,
          description = {
            "Legendary siege weapon of mass destruction. ",
            "Can reach targets across the entire battlefield. ",
          },
          hints = {
            { field = TowerStatField.RANGE, hint = UpgradeHint.GOOD },
            { field = TowerStatField.DAMAGE, hint = UpgradeHint.GOOD },
          },
          on_accept = function(_evolution, tower)
            local operations = {
              TowerStatOperation.base_range(1.5),
              TowerStatOperation.base_damage(20),
            }
            for _, operation in ipairs(operations) do
              operation:apply_to_tower_stats(tower.stats_base)
            end
          end,
        },
      },
    }
  elseif self.level == 6 and self._tags.bombard then
    return TowerLevelUpReward.new {
      kind = LevelUpRewardKind.EVOLVE_TOWER,
      reward = {
        TowerEvolutionOption.new {
          title = "Bombard Tower++",
          tower_name = "Bombard Tower++",
          texture = sprites.tower_catapault_loaded,
          description = {
            "Cataclysmic explosions that reshape the battlefield. ",
            "Ultimate area denial weapon. ",
          },
          hints = {
            { field = TowerStatField.AOE, hint = UpgradeHint.GOOD },
            { field = TowerStatField.DAMAGE, hint = UpgradeHint.GOOD },
          },
          on_accept = function(_evolution, tower)
            local operations = {
              TowerStatOperation.base_aoe(1),
              TowerStatOperation.base_damage(15),
            }
            for _, operation in ipairs(operations) do
              operation:apply_to_tower_stats(tower.stats_base)
            end
          end,
        },
      },
    }
  else
    return Tower.get_levelup_reward(self)
  end
end

---@return table<TowerStatField, table<Rarity, tower.UpgradeOption>>
function CatapaultTower:get_tower_stat_enhancements() return base_enhancements end

---@return table<Rarity, tower.UpgradeOption[]>
function CatapaultTower:get_upgrade_options() return enhancements_by_rarity end

--- Create a projectile when attacking
---@param target vibes.Enemy
function CatapaultTower:attack(target)
  -- TODO: I think we should maybe not call it left and right, but idk
  if target.position.x < self.position.x then
    self.state.sprite_orientation = "left"
  else
    self.state.sprite_orientation = "right"
  end

  local src = self:get_projectile_starting_position()
  local dst = target.position:clone()
  local direction = dst:sub(src):normalize()
  local final = src:add(direction:scale(self:get_range_in_distance() * 1.2))

  return Projectile.new {
    src = src,
    dst = final,
    speed = 5,
    durability = 1,
    texture = Asset.sprites.projectile_boulder,
    on_collide = function(_, enemy)
      local enemies =
        GameFunctions.enemies_within(enemy.position, self.stats_base.aoe.value)

      for _, enemy in ipairs(enemies) do
        local projectile_damage = self:get_damage()
        State:damage_enemy {
          source = self,
          enemy = enemy,
          damage = projectile_damage,
          kind = DamageKind.PHYSICAL,
        }
      end

      -- Play multiple explosions scaled to the AOE size
      GameAnimationSystem:play_aoe_explosions(
        enemy.position,
        self.stats_base.aoe.value
      )
    end,
  }
end

return CatapaultTower
