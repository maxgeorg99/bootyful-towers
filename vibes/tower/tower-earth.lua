local Projectile = require "vibes.projectile"
local Tower = require "vibes.tower.base"
local TowerUtils = require "vibes.tower.tower-utils"
local sprites = require("vibes.asset").sprites

local TowerEvolutionOption = require "vibes.tower.meta.tower-evolution-option"
local TowerLevelUpReward = require "vibes.tower.meta.tower-levelup-reward"
local TowerUpgradeOption = require "vibes.tower.meta.tower-upgrade-option"

---@class vibes.EarthBolt : vibes.Projectile
---@field new fun(opts: vibes.EarthBolt.Opts): vibes.EarthBolt
---@field init fun(self: vibes.EarthBolt, opts: vibes.EarthBolt.Opts)
local EarthBolt = class("vibes.EarthBolt", { super = Projectile })

---@class vibes.EarthBolt.Opts
---@field source vibes.Tower
---@field src vibes.Position
---@field dst vibes.Position
---@field speed number
---@field durability number
---@field texture vibes.Texture
---@field block_amount number

---@param opts vibes.EarthBolt.Opts
function EarthBolt:init(opts)
  local source = assert(opts.source, "source is required")
  local block_amount = opts.block_amount or source:get_damage()

  local on_collide = function(p, enemy)
    -- Give block to the player instead of damaging the enemy
    State:give_player_block(block_amount)
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

function EarthBolt:update(dt) Projectile.update(self, dt) end
function EarthBolt:draw()
  love.graphics.setColor(0.6, 0.4, 0.2, 0.8) -- Brown/earth color

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

---@class vibes.EarthTower : vibes.Tower
---@field new fun()
---@field init fun(self: vibes.EarthTower)
---@field tower vibes.EarthTower
---@field _base_stats tower.Stats
---@field _projectile_texture vibes.Texture
---@field _tags { mother_nature: boolean, overgrowth: boolean, charm: boolean }
local EarthTower = class("vibes.EarthTower", { super = Tower })

EarthTower._base_stats = TowerStats.new {
  range = Stat.new(3, 1), -- Moderate range
  damage = Stat.new(2, 1), -- Low damage stat, used for block amount instead
  attack_speed = Stat.new(1.0, 1), -- Slower attack speed
  enemy_targets = Stat.new(1, 1), -- Targets one enemy
}

function EarthTower:init()
  Tower.init(
    self,
    self._base_stats:clone(),
    sprites.tower_tar, -- Using tar tower sprite as earth-like placeholder
    { kind = TowerKind.SHOOTER, element_kind = ElementKind.EARTH }
  )

  self._projectile_texture = sprites.projectile_boulder
  self._tags = {
    mother_nature = false,
    overgrowth = false,
    charm = false,
  }
end

---@type table<TowerStatField, table<Rarity, tower.UpgradeOption>>
local base_enhancements = {
  [TowerStatField.DAMAGE] = TowerUtils.damage_by_list { 6, 10, 16, 32, 64 },
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
      name = "Increase Attack Speed",
      rarity = Rarity.COMMON,
      operations = { TowerStatOperation.base_attack_speed(0.25) },
    },

    TowerUpgradeOption.new {
      name = "Increase Block Amount",
      rarity = Rarity.COMMON,
      operations = { TowerStatOperation.base_damage(2) }, -- Damage stat used as block amount
    },
  },

  [Rarity.UNCOMMON] = {
    TowerUpgradeOption.new {
      name = "Range & attack speed boost",
      rarity = Rarity.UNCOMMON,
      operations = {
        TowerStatOperation.base_range(0.25),
        TowerStatOperation.base_attack_speed(0.125),
      },
    },

    TowerUpgradeOption.new {
      name = "Block & range boost",
      rarity = Rarity.UNCOMMON,
      operations = {
        TowerStatOperation.base_damage(1),
        TowerStatOperation.base_range(0.25),
      },
    },

    TowerUpgradeOption.new {
      name = "Durability boost",
      rarity = Rarity.UNCOMMON,
      operations = {
        TowerStatOperation.base_durability(1),
      },
    },
  },

  [Rarity.RARE] = {
    TowerUpgradeOption.new {
      name = "Block & durability boost",
      rarity = Rarity.RARE,
      operations = {
        TowerStatOperation.base_damage(1),
        TowerStatOperation.base_durability(1),
      },
    },

    TowerUpgradeOption.new {
      name = "Range & durability boost",
      rarity = Rarity.RARE,
      operations = {
        TowerStatOperation.base_range(0.25),
        TowerStatOperation.base_durability(1),
      },
    },

    TowerUpgradeOption.new {
      name = "Attack speed & durability boost",
      rarity = Rarity.RARE,
      operations = {
        TowerStatOperation.base_attack_speed(0.125),
        TowerStatOperation.base_durability(1),
      },
    },
  },

  [Rarity.EPIC] = {
    TowerUpgradeOption.new {
      name = "Balanced improvement",
      rarity = Rarity.EPIC,
      operations = {
        TowerStatOperation.base_damage(1),
        TowerStatOperation.base_attack_speed(0.125),
        TowerStatOperation.base_range(0.25),
        TowerStatOperation.base_durability(1),
      },
    },

    TowerUpgradeOption.new {
      name = "Durability boost",
      rarity = Rarity.EPIC,
      operations = {
        TowerStatOperation.base_durability(2),
      },
    },
  },

  [Rarity.LEGENDARY] = {
    TowerUpgradeOption.new {
      name = "Major durability boost",
      rarity = Rarity.LEGENDARY,
      operations = {
        TowerStatOperation.base_durability(3),
      },
    },
    TowerUpgradeOption.new {
      name = "Major block boost",
      rarity = Rarity.LEGENDARY,
      operations = { TowerStatOperation.base_damage(3) },
    },
  },
}

---@return table<TowerStatField, table<Rarity, tower.UpgradeOption>>
function EarthTower:get_tower_stat_enhancements() return base_enhancements end

---@return table<Rarity, tower.UpgradeOption[]>
function EarthTower:get_upgrade_options() return enhancements_by_rarity end

---@param initial_target vibes.Enemy
function EarthTower:_create_projectile(initial_target)
  SoundManager:play_shoot_arrow(0.8) -- Lower pitch for earth sound

  local enemy_position = initial_target.position:clone()
  local direction = enemy_position:sub(self.position)
  local dst =
    self.position:add(direction:normalize():scale(self:get_range_in_distance()))

  local e = EarthBolt.new {
    src = Position.from_cell(self.cell),
    dst = dst,
    speed = 5, -- Slower than lightning
    durability = 3, -- Can hit multiple enemies
    source = self,
    texture = self._projectile_texture,
    block_amount = self:get_damage(), -- Use damage stat as block amount
    knockback_multiplier = 10,
  }

  return e
end

function EarthTower:get_levelup_reward()
  if self.level == 3 then
    return TowerLevelUpReward.new {
      kind = LevelUpRewardKind.EVOLVE_TOWER,
      reward = {
        -- Earth: Mother Nature, adds Health to the player
        TowerEvolutionOption.new {
          title = "Earth Tower+",
          tower_name = "Earth Tower+",
          texture = sprites.tower_tar,
          description = {
            "If enemies are within range for every X # of ticks, add Health to the player",
            "Doesn't hurt",
          },
          hints = {
            { field = TowerStatField.RANGE, hint = UpgradeHint.GOOD },
          },
          on_accept = function(_, tower)
            ---@cast tower vibes.EarthTower
            tower._tags.mother_nature = true
          end,
        },
        -- Earth: Overgrowth, adds Defense to the player
        TowerEvolutionOption.new {
          title = "Earth Tower+ (1)",
          tower_name = "Earth Tower+ (1)",
          texture = sprites.tower_tar,
          description = {
            "If enemies are within range for every X # of ticks, add Defense to the player",
            "Doesn't hurt",
            "Certain enemies avoid player defenses",
          },
          hints = {
            { field = TowerStatField.RANGE, hint = UpgradeHint.GOOD },
          },
          on_accept = function(_, tower)
            ---@cast tower vibes.EarthTower
            tower._tags.overgrowth = true
          end,
        },
        -- Earth: Charm, makes enemies your friend
        TowerEvolutionOption.new {
          title = "Earth Tower+ (2)",
          tower_name = "Earth Tower+ (2)",
          texture = sprites.tower_tar,
          description = {
            "Makes enemies your friend and they attack other enemies for you!",
          },
          hints = {
            { field = TowerStatField.RANGE, hint = UpgradeHint.GOOD },
          },
          on_accept = function(_, tower)
            ---@cast tower vibes.EarthTower
            tower._tags.charm = true
          end,
        },
      },
    }
  elseif self.level == 5 and self._tags.mother_nature then
    return TowerLevelUpReward.new {
      kind = LevelUpRewardKind.EVOLVE_TOWER,
      reward = {
        TowerEvolutionOption.new {
          title = "Earth Tower+ (1)",
          tower_name = "Earth Tower+ (1)",
          texture = sprites.tower_tar,
          description = {
            "If enemies are within range for every X # of ticks, add Health to the player",
            "Doesn't hurt",
          },
          hints = {
            { field = TowerStatField.RANGE, hint = UpgradeHint.GOOD },
          },
          on_accept = function(_evolution, tower) end,
        },
      },
    }
  elseif self.level == 5 and self._tags.overgrowth then
    return TowerLevelUpReward.new {
      kind = LevelUpRewardKind.EVOLVE_TOWER,
      reward = {
        TowerEvolutionOption.new {
          title = "Earth Tower+ (2)",
          tower_name = "Earth Tower+ (2)",
          texture = sprites.tower_tar,
          description = {
            "If enemies are within range for every X # of ticks, add Defense to the player",
            "Doesn't hurt",
            "Certain enemies avoid player defenses",
          },
          hints = {
            { field = TowerStatField.RANGE, hint = UpgradeHint.GOOD },
          },
          on_accept = function(_evolution, tower) end,
        },
      },
    }
  elseif self.level == 5 and self._tags.charm then
    return TowerLevelUpReward.new {
      kind = LevelUpRewardKind.EVOLVE_TOWER,
      reward = {
        TowerEvolutionOption.new {
          title = "Earth Tower+ (3)",
          tower_name = "Earth Tower+ (3)",
          texture = sprites.tower_tar,
          description = {
            "Makes enemies your friend and they attack other enemies for you!",
          },
          hints = {
            { field = TowerStatField.RANGE, hint = UpgradeHint.GOOD },
          },
          on_accept = function(_evolution, tower) end,
        },
      },
    }
  elseif self.level == 6 and self._tags.mother_nature then
    return TowerLevelUpReward.new {
      kind = LevelUpRewardKind.EVOLVE_TOWER,
      reward = {
        TowerEvolutionOption.new {
          title = "Earth Tower+ (2)",
          tower_name = "Earth Tower+ (2)",
          texture = sprites.tower_tar,
          description = {
            "If enemies are within range for every X # of ticks, add Health to the player",
            "Doesn't hurt",
          },
          hints = {
            { field = TowerStatField.RANGE, hint = UpgradeHint.GOOD },
          },
          on_accept = function(_evolution, tower) end,
        },
      },
    }
  elseif self.level == 6 and self._tags.overgrowth then
    return TowerLevelUpReward.new {
      kind = LevelUpRewardKind.EVOLVE_TOWER,
      reward = {
        TowerEvolutionOption.new {
          title = "Earth Tower+ (3)",
          tower_name = "Earth Tower+ (3)",
          texture = sprites.tower_tar,
          description = {
            "If enemies are within range for every X # of ticks, add Defense to the player",
            "Doesn't hurt",
            "Certain enemies avoid player defenses",
          },
          hints = {
            { field = TowerStatField.RANGE, hint = UpgradeHint.GOOD },
          },
          on_accept = function(_evolution, tower) end,
        },
      },
    }
  elseif self.level == 6 and self._tags.charm then
    return TowerLevelUpReward.new {
      kind = LevelUpRewardKind.EVOLVE_TOWER,
      reward = {
        TowerEvolutionOption.new {
          title = "Earth Tower+ (4)",
          tower_name = "Earth Tower+ (4)",
          texture = sprites.tower_tar,
          description = {
            "Makes enemies your friend and they attack other enemies for you!",
          },
          hints = {
            { field = TowerStatField.RANGE, hint = UpgradeHint.GOOD },
          },
          on_accept = function(_evolution, tower) end,
        },
      },
    }
  else
    return Tower.get_levelup_reward(self)
  end
end

--- Create a projectile when attacking
---@param target vibes.Enemy
---@return vibes.Projectile
function EarthTower:attack(target) return self:_create_projectile(target) end

return EarthTower
