local Projectile = require "vibes.projectile"
local Tower = require "vibes.tower.base"
local TowerUtils = require "vibes.tower.tower-utils"
local sprites = require("vibes.asset").sprites

local TowerEvolutionOption = require "vibes.tower.meta.tower-evolution-option"
local TowerLevelUpReward = require "vibes.tower.meta.tower-levelup-reward"
local TowerUpgradeOption = require "vibes.tower.meta.tower-upgrade-option"

---@type table<TowerStatField, table<Rarity, tower.UpgradeOption>>
local base_enhancements = {
  [TowerStatField.DAMAGE] = TowerUtils.damage_by_list { 12, 18, 30, 60, 120 },
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

    -- Critical-focused, low values
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

---@class vibes.LightningBolt : vibes.Projectile
---@field new fun(opts: vibes.LightningBolt.Opts): vibes.LightningBolt
---@field init fun(self: vibes.LightningBolt, opts: vibes.LightningBolt.Opts)
local LightningBolt = class("vibes.LightningBolt", { super = Projectile })

---@class vibes.LightningBolt.Opts
---@field source vibes.Tower
---@field src vibes.Position
---@field dst vibes.Position
---@field speed number
---@field durability number
---@field texture vibes.Texture

---@param opts vibes.LightningBolt.Opts
function LightningBolt:init(opts)
  local source = assert(opts.source, "source is required")

  self._damage_multipler = 1
  self._incremental_multipler = 1.2

  local on_collide = function(p, enemy)
    State:damage_enemy {
      source = source,
      enemy = enemy,
      damage = source:get_damage() * self._damage_multipler,
      -- TODO: Lightning
      kind = DamageKind.PHYSICAL,
    }

    self._damage_multipler = self._damage_multipler
      * self._incremental_multipler
    if p.durability < 1 then
      return
    end

    -- Find the next closest enemy, and set our target to it
    local GameFunctions = require "vibes.data.game-functions"
    local enemies = GameFunctions.enemies_within(p.src, 4)
    for _, enemy in ipairs(enemies) do
      if p:can_target_enemy(enemy) then
        local dst = enemy.position:clone()
        p.get_dst = function() return dst end
        return
      end
    end

    -- If we can't find anything to jump to, we just remove the projectile
    p:remove()
  end

  Projectile.init(self, {
    src = opts.src,
    dst = opts.dst,
    speed = opts.speed,
    durability = opts.durability,
    texture = opts.texture,
    on_collide = on_collide,
  })
end

function LightningBolt:update(dt) Projectile.update(self, dt) end
function LightningBolt:draw()
  love.graphics.setColor(1, 1, 1, 0.5)

  local width = self.texture:getWidth()
  local height = self.texture:getHeight()
  love.graphics.draw(
    self.texture,
    self.src.x - width / 2,
    self.src.y - height / 2,
    0,
    1,
    1
  )
end

---@class vibes.LightningTower : vibes.Tower
---@field new fun()
---@field init fun(self: vibes.LightningTower)
---@field tower vibes.LightningTower
---@field _tags { coffee: boolean, lightning: boolean, faraday: boolean }
---@field _base_stats tower.Stats
---@field _projectile_texture vibes.Texture
local LightningTower = class("vibes.LightningTower", { super = Tower })

LightningTower._base_stats = TowerStats.new {
  range = Stat.new(4, 1), -- Extended range
  damage = Stat.new(3, 1), -- Updated damage to 10
  attack_speed = Stat.new(1.5, 1), -- Attacks per second
  enemy_targets = Stat.new(1, 1), -- Targets one enemy
}

function LightningTower:init()
  Tower.init(
    self,
    self._base_stats:clone(),
    sprites.tower_archer,
    { kind = TowerKind.SHOOTER, element_kind = ElementKind.AIR }
  )

  self._tags = {
    coffee = false,
    lightning = false,
    faraday = false,
  }

  self._projectile_texture = sprites.orb_radiant
end

function LightningTower:get_levelup_reward()
  if self.level == 3 then
    return TowerLevelUpReward.new {
      kind = LevelUpRewardKind.EVOLVE_TOWER,
      reward = {
        TowerEvolutionOption.new {
          title = "Coffee Tower",
          tower_name = "Coffee Tower",
          texture = sprites.tower_archer,
          description = {
            "Increases Tower's range",
            "Increases the Tower's Attack speed",
          },
          hints = {
            { field = TowerStatField.RANGE, hint = UpgradeHint.GOOD },
            { field = TowerStatField.ATTACK_SPEED, hint = UpgradeHint.GOOD },
          },
          ---@param _evolution tower.EvolutionOption
          ---@param tower vibes.LightningTower
          on_accept = function(_evolution, tower) tower._tags.coffee = true end,
        },
        TowerEvolutionOption.new {
          title = "Lightning Tower",
          tower_name = "Lightning Tower",
          texture = sprites.tower_archer,
          description = {
            "Causes Lightning to have a % chance to Stun Enemies",
          },
          hints = {
            { field = TowerStatField.DAMAGE, hint = UpgradeHint.GOOD },
          },
          ---@param _evolution tower.EvolutionOption
          ---@param tower vibes.LightningTower
          on_accept = function(_evolution, tower) tower._tags.lightning = true end,
        },
        TowerEvolutionOption.new {
          title = "Faraday Cage",
          tower_name = "Faraday Cage",
          texture = sprites.tower_archer,
          description = {
            "Lightning can bounce from one Enemy to another",
          },
          hints = {
            { field = TowerStatField.ENEMY_TARGETS, hint = UpgradeHint.GOOD },
          },
          ---@param _evolution tower.EvolutionOption
          ---@param tower vibes.LightningTower
          on_accept = function(_evolution, tower) tower._tags.faraday = true end,
        },
      },
    }
  elseif self.level == 5 and self._tags.coffee then
    return TowerLevelUpReward.new {
      kind = LevelUpRewardKind.EVOLVE_TOWER,
      reward = {
        TowerEvolutionOption.new {
          title = "Coffee Tower+",
          tower_name = "Coffee Tower+",
          texture = sprites.tower_archer,
          description = {
            "Increases Tower's range",
            "Increases the Tower's Attack speed",
          },
          hints = {
            { field = TowerStatField.RANGE, hint = UpgradeHint.GOOD },
            { field = TowerStatField.ATTACK_SPEED, hint = UpgradeHint.GOOD },
          },
          ---@param _evolution tower.EvolutionOption
          ---@param tower vibes.LightningTower
          on_accept = function(_evolution, tower)
            local operations = {
              TowerStatOperation.base_range(1.0),
              TowerStatOperation.base_attack_speed(0.5),
            }
            for _, operation in ipairs(operations) do
              operation:apply_to_tower_stats(tower.stats_base)
            end
          end,
        },
      },
    }
  elseif self.level == 5 and self._tags.lightning then
    return TowerLevelUpReward.new {
      kind = LevelUpRewardKind.EVOLVE_TOWER,
      reward = {
        TowerEvolutionOption.new {
          title = "Lightning Tower+",
          tower_name = "Lightning Tower+",
          texture = sprites.tower_archer,
          description = {
            "Causes Lightning to have a % chance to Stun Enemies",
          },
          hints = {
            { field = TowerStatField.DAMAGE, hint = UpgradeHint.GOOD },
          },
          ---@param _evolution tower.EvolutionOption
          ---@param tower vibes.LightningTower
          on_accept = function(_evolution, tower) tower._tags.lightning = true end,
        },
      },
    }
  elseif self.level == 5 and self._tags.faraday then
    return TowerLevelUpReward.new {
      kind = LevelUpRewardKind.EVOLVE_TOWER,
      reward = {
        TowerEvolutionOption.new {
          title = "Faraday Cage+",
          tower_name = "Faraday Cage+",
          texture = sprites.tower_archer,
          description = {
            "Lightning can bounce from one Enemy to another",
          },
          hints = {
            { field = TowerStatField.ENEMY_TARGETS, hint = UpgradeHint.GOOD },
          },
          ---@param _evolution tower.EvolutionOption
          ---@param tower vibes.LightningTower
          on_accept = function(_evolution, tower) tower._tags.faraday = true end,
        },
      },
    }
  elseif self.level == 6 and self._tags.coffee then
    return TowerLevelUpReward.new {
      kind = LevelUpRewardKind.EVOLVE_TOWER,
      reward = {
        TowerEvolutionOption.new {
          title = "Coffee Tower++",
          tower_name = "Coffee Tower++",
          texture = sprites.tower_archer,
          description = {
            "Increases Tower's range",
            "Increases the Tower's Attack speed",
          },
          hints = {
            { field = TowerStatField.RANGE, hint = UpgradeHint.GOOD },
            { field = TowerStatField.ATTACK_SPEED, hint = UpgradeHint.GOOD },
          },
          ---@param _evolution tower.EvolutionOption
          ---@param tower vibes.LightningTower
          on_accept = function(_evolution, tower)
            local operations = {
              TowerStatOperation.base_range(1.0),
              TowerStatOperation.base_attack_speed(0.5),
            }
            for _, operation in ipairs(operations) do
              operation:apply_to_tower_stats(tower.stats_base)
            end
          end,
        },
      },
    }
  elseif self.level == 6 and self._tags.lightning then
    return TowerLevelUpReward.new {
      kind = LevelUpRewardKind.EVOLVE_TOWER,
      reward = {
        TowerEvolutionOption.new {
          title = "Lightning Tower++",
          tower_name = "Lightning Tower++",
          texture = sprites.tower_archer,
          description = {
            "Causes Lightning to have a % chance to Stun Enemies",
          },
          hints = {
            { field = TowerStatField.DAMAGE, hint = UpgradeHint.GOOD },
          },
          ---@param _evolution tower.EvolutionOption
          ---@param tower vibes.LightningTower
          on_accept = function(_evolution, tower) tower._tags.lightning = true end,
        },
      },
    }
  elseif self.level == 6 and self._tags.faraday then
    return TowerLevelUpReward.new {
      kind = LevelUpRewardKind.EVOLVE_TOWER,
      reward = {
        TowerEvolutionOption.new {
          title = "Faraday Cage++",
          tower_name = "Faraday Cage++",
          texture = sprites.tower_archer,
          description = {
            "Lightning can bounce from one Enemy to another",
          },
          hints = {
            { field = TowerStatField.ENEMY_TARGETS, hint = UpgradeHint.GOOD },
          },
          ---@param _evolution tower.EvolutionOption
          ---@param tower vibes.LightningTower
          on_accept = function(_evolution, tower) tower._tags.faraday = true end,
        },
      },
    }
  else
    return Tower.get_levelup_reward(self)
  end
end

---@return table<TowerStatField, table<Rarity, tower.UpgradeOption>>
function LightningTower:get_tower_stat_enhancements() return base_enhancements end

---@return table<Rarity, tower.UpgradeOption[]>
function LightningTower:get_upgrade_options() return enhancements_by_rarity end

function LightningTower:get_projectile_starting_position()
  return Position.from_cell(self.cell)
    :add(Position.new(0, -Config.grid.cell_size * 0.75))
end

---@param initial_target vibes.Enemy
function LightningTower:_create_projectile(initial_target)
  SoundManager:play_shoot_arrow(1.5)

  local enemy_position = initial_target.position:clone()
  local direction = enemy_position:sub(self.position)
  local dst =
    self.position:add(direction:normalize():scale(self:get_range_in_distance()))

  return LightningBolt.new {
    src = enemy_position,
    dst = dst,
    speed = 7,
    durability = 10,
    starting_damage = self:get_damage(),
    source = self,
    texture = self._projectile_texture,
  }
end

--- Create a projectile when attacking
---@param target vibes.Enemy
---@return vibes.Projectile
function LightningTower:attack(target) return self:_create_projectile(target) end

return LightningTower
