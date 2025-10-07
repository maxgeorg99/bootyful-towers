local Projectile = require "vibes.projectile"
local Tower = require "vibes.tower.base"
local sprites = require("vibes.asset").sprites
local TowerUtils = require "vibes.tower.tower-utils"

local TowerEvolutionOption = require "vibes.tower.meta.tower-evolution-option"
local TowerLevelUpReward = require "vibes.tower.meta.tower-levelup-reward"
local TowerUpgradeOption = require "vibes.tower.meta.tower-upgrade-option"

---@class vibes.ArcherTower : vibes.Tower
---@field new fun()
---@field init fun(self: vibes.ArcherTower)
---@field _base_stats tower.Stats
---@field _projectile_texture vibes.Texture
---@field _tags { longbow: boolean, crossbow: boolean, improved_enhancements?: number }
local ArcherTower = class("vibes.ArcherTower", { super = Tower })

ArcherTower._base_stats = TowerStats.new {
  range = Stat.new(3.5, 1), -- Extended default range
  damage = Stat.new(5, 1), -- Increased base damage for more effectiveness
  attack_speed = Stat.new(1.5, 1), -- Attacks per second
  enemy_targets = Stat.new(1, 1), -- Targets one enemy
  -- critical = Stat.new(1, 1),
}

function ArcherTower:init()
  Tower.init(
    self,
    self._base_stats:clone(),
    sprites.tower_archer,
    { kind = TowerKind.SHOOTER, element_kind = ElementKind.PHYSICAL }
  )

  self._projectile_texture = sprites.projectile_arrow
  self._tags = {
    longbow = false,
    crossbow = false,
    improved_enhancements = 1,
  }
end

---@return number
function ArcherTower:initial_experience() return 300 end

---@type table<TowerStatField, table<Rarity, tower.UpgradeOption[]>>
local base_enhancements = {
  [TowerStatField.DAMAGE] = TowerUtils.damage_by_list { 2, 3, 5, 10, 20 },
  [TowerStatField.ATTACK_SPEED] = TowerUtils.attack_speed_by_list {
    0.25,
    0.35,
    0.5,
    1,
    2,
  },
  [TowerStatField.RANGE] = TowerUtils.range_by_list { 0.5, 0.65, 0.8, 1, 1.5 },
  [TowerStatField.CRITICAL] = TowerUtils.critical_by_list {
    0.01,
    0.02,
    0.05,
    0.1,
    0.15,
  },
}

---@type table<Rarity, tower.UpgradeOption[]>
local enhancements_by_rarity =
  TowerUtils.convert_enhancement_by_type_to_rarity(base_enhancements)

---@type table<Rarity, tower.UpgradeOption[]>
local special_enhancements = {
  [Rarity.LEGENDARY] = {
    TowerUpgradeOption.new {
      name = "Durability +1",
      rarity = Rarity.LEGENDARY,
      operations = { TowerStatOperation.base_durability(1) },
    },
  },
}

---TODO: Likely move this to base tower
---@param operations tower.StatOperation[]
local function apply_improved_enhancements(operations, amount)
  for _, operation in ipairs(operations) do
    operation.operation.value = operation.operation.value * amount
  end
end

---@return table<TowerStatField, table<Rarity, tower.UpgradeOption[]>>
function ArcherTower:get_tower_stat_enhancements() return base_enhancements end

---@return table<Rarity, tower.UpgradeOption[]>
function ArcherTower:get_upgrade_options()
  ---@type table<Rarity, tower.UpgradeOption[]>
  local upgrades = {}

  --- TODO: Prime, likely to run into this transformation for all towers
  --- improved_enhancements should probably be upleveled to the base tower
  if
    self._tags.improved_enhancements and self._tags.improved_enhancements ~= 1
  then
    for rarity, options in pairs(enhancements_by_rarity) do
      upgrades[rarity] = {}
      for _, option in ipairs(options) do
        ---@type tower.UpgradeOption
        local new_option = option:clone()

        apply_improved_enhancements(
          new_option.operations,
          self._tags.improved_enhancements
        )
        table.insert(upgrades[rarity], new_option)
      end
    end
  else
    upgrades = enhancements_by_rarity
  end

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

---@return tower.LevelUpReward
function ArcherTower:evolution_options()
  return TowerLevelUpReward.new {
    kind = LevelUpRewardKind.EVOLVE_TOWER,
    reward = {
      TowerEvolutionOption.new {
        title = "Longbow Tower",
        texture = sprites.tower_archer_longbow,
        description = {
          "Does more damage the further it is from the target.",
          "Has {range:+1 range} multiplier.",
        },
        hints = {
          { field = TowerStatField.RANGE, hint = UpgradeHint.GOOD },
          { field = TowerStatField.DAMAGE, hint = UpgradeHint.BAD },
        },

        ---@param _evolution tower.EvolutionOption
        ---@param tower vibes.ArcherTower
        on_accept = function(_evolution, tower)
          tower.texture = sprites.tower_archer_longbow
          tower._tags.longbow = true

          -- TODO: Can change the arrow texture here, which is cool
          -- tower._projectile_texture = sprites.projectile_arrow_longbow

          local operations = { TowerStatOperation.base_range(1) }
          for _, operation in ipairs(operations) do
            operation:apply_to_tower_stats(tower.stats_base)
          end
        end,
      },
      TowerEvolutionOption.new {
        title = "Crossbow Tower",
        texture = sprites.tower_archer_crossbow,
        description = {
          "Adds {durability:+2 durability}. Arrows now pierce through enemies.",
        },
        hints = {
          { field = TowerStatField.DURABILITY, hint = UpgradeHint.GOOD },
        },

        ---@param _evolution tower.EvolutionOption
        ---@param tower vibes.ArcherTower
        on_accept = function(_evolution, tower)
          tower.texture = sprites.tower_archer_crossbow
          tower._tags.crossbow = true

          local operations = { TowerStatOperation.base_durability(2) }
          for _, operation in ipairs(operations) do
            operation:apply_to_tower_stats(tower.stats_base)
          end
        end,
      },
      TowerEvolutionOption.new {
        title = "Archer++",
        texture = sprites.tower_archer,
        description = {
          "All enhancements applied to this tower have increased effectiveness of 50%",
        },
        hints = { { field = TowerStatField.DAMAGE, hint = UpgradeHint.GOOD } },

        ---@param _evolution tower.EvolutionOption
        ---@param tower vibes.ArcherTower
        on_accept = function(_evolution, tower)
          tower.texture = sprites.tower_archer
          self._tags.improved_enhancements = 1.5
        end,
      },
    },
  }
end

---@return tower.LevelUpReward
function ArcherTower:get_levelup_reward()
  if self.level == 5 then
    return self:evolution_options()
  end

  return Tower.get_levelup_reward(self)
end

function ArcherTower:get_projectile_starting_position()
  return Position.from_cell(self.cell):add(
    Position.new(
      0 + math.random(-10, 10),
      -Config.grid.cell_size * 0.5 + math.random(-10, 10)
    )
  )
end

---@param initial_target vibes.Enemy
function ArcherTower:_create_projectile(initial_target)
  SoundManager:play_shoot_arrow(1.5)

  local enemy_position = initial_target.center:clone()
  local direction = enemy_position:sub(self.position):normalize()
  local src = self:get_projectile_starting_position()
  local dst = src:add(direction:scale(self:get_range_in_distance() * 1.3))

  return Projectile.new {
    src = src,
    dst = dst,
    speed = function() return TrueRandom:decimal_range(10, 12) end,
    durability = self:get_durability(),
    texture = self._projectile_texture,
    on_collide = function(projectile, enemy)
      enemy:apply_blood_stack(self, 1)

      local damage = self:get_damage()
      if self._tags.longbow then
        local distance = self.position:distance(enemy.position)
        local range = self:get_range_in_distance()
        damage = damage * (0.75 + distance / range)
      end

      State:damage_enemy {
        source = self,
        enemy = enemy,
        damage = damage,
        kind = DamageKind.PHYSICAL,
      }
    end,
  }
end

--- Create a projectile when attacking
---@param target vibes.Enemy
---@return vibes.Projectile
function ArcherTower:attack(target)
  local projectile = self:_create_projectile(target)

  return projectile
end

function ArcherTower:__tostring()
  return string.format(
    "ArcherTower(id=%s, lvl=%s, tags=%s)",
    self.id,
    self.level,
    inspect(self._tags)
  )
end

return ArcherTower
