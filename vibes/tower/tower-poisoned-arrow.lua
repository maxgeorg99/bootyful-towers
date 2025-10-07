local Projectile = require "vibes.projectile"
local Tower = require "vibes.tower.base"
local TowerUtils = require "vibes.tower.tower-utils"
local sprites = require("vibes.asset").sprites

local TowerEvolutionOption = require "vibes.tower.meta.tower-evolution-option"
local TowerLevelUpReward = require "vibes.tower.meta.tower-levelup-reward"
local TowerUpgradeOption = require "vibes.tower.meta.tower-upgrade-option"

---@class vibes.PoisonedArrowTower : vibes.Tower
---@field new fun()
---@field init fun(self: vibes.PoisonedArrowTower)
---@field tower vibes.PoisonedArrowTower
---@field _base_stats tower.Stats
---@field _projectile_texture vibes.Texture
---@field _tags { sludge: boolean, poison_pool: boolean, poison_bolt: boolean }
local PoisonedArrowTower = class("vibes.PoisonedArrowTower", { super = Tower })

PoisonedArrowTower._base_stats = TowerStats.new {
  range = Stat.new(4, 1), -- Increased range
  damage = Stat.new(1, 1), -- Base poison stacks per hit
  attack_speed = Stat.new(1.5, 1), -- Attacks per second
  enemy_targets = Stat.new(1, 1), -- Targets one enemy
}

function PoisonedArrowTower:init()
  Tower.init(
    self,
    self._base_stats:clone(),
    sprites.tower_poisoned_arrow,
    { kind = TowerKind.SHOOTER, element_kind = ElementKind.POISON }
  )

  -- TODO: Poison arrow texture
  self._projectile_texture = sprites.projectile_arrow
  self._tags = {
    sludge = false,
  }
end

function PoisonedArrowTower:_create_projectile(initial_target)
  -- TODO: Share this between the archer and longbow?
  SoundManager:play_shoot_arrow(1.5)

  return Projectile.new {
    src = Position.from_cell(self.cell),
    dst = initial_target.center:clone(),
    speed = 10,
    durability = self:get_durability(),
    texture = self._projectile_texture,
    on_collide = function(_, enemy)
      if self._tags.poison_bolt then
        local stacks = enemy.poison_stacks
        enemy:clear_poison_stacks()

        State:damage_enemy {
          source = self,
          enemy = enemy,
          damage = stacks * 2,
          kind = DamageKind.PHYSICAL,
        }

        return
      end

      if self._tags.sludge and enemy.statuses.poisoned then
        enemy.statuses.sludged = true
      end

      if self._tags.poison_pool then
        enemy.statuses.poison_pool = true
      end

      -- Apply poison stacks based on tower damage
      local poison_stacks = math.max(1, math.floor(self:get_damage()))
      enemy:apply_poison_stack(self, poison_stacks)
    end,
  }
end

--- Create a projectile when attacking
---@param target vibes.Enemy
---@return vibes.Projectile
function PoisonedArrowTower:attack(target)
  return self:_create_projectile(target)
end

function PoisonedArrowTower:get_levelup_reward()
  -- Sludge Tower
  if self.level == 3 then
    return TowerLevelUpReward.new {
      kind = LevelUpRewardKind.EVOLVE_TOWER,
      reward = {
        -- Poison: Sludge Tower, slows poisoned enemy
        TowerEvolutionOption.new {
          title = "Sludge Tower",
          tower_name = "Sludge Tower",
          texture = sprites.tower_poison or sprites.orb_range,
          description = { "Slows already {poison:poisoned} enemies." },
          hints = {
            -- { field = TowerStatField.ATTACK_SPEED, hint = UpgradeHint.GOOD },
          },
          on_accept = function(_, tower)
            ---@cast tower vibes.PoisonedArrowTower
            tower._tags.sludge = true
          end,
        },
        -- Poison: Poison Pool, if enemy dies from poison, create a pool of poison
        TowerEvolutionOption.new {
          title = "Poison Pool",
          tower_name = "Poison Pool",
          texture = sprites.tower_poisoned_arrow or sprites.orb_range,
          description = {
            "If enemy dies from poison, create a pool of poison.",
          },
          hints = {
            -- { field = TowerStatField.ATTACK_SPEED, hint = UpgradeHint.GOOD },
          },
          on_accept = function(_, tower)
            ---@cast tower vibes.PoisonedArrowTower
            tower._tags.poison_pool = true
          end,
        },
        -- Poison: Poison Bolt, takes all current stacks of poison and does double damage. then sets stacks to 0
        TowerEvolutionOption.new {
          title = "Poison Bolt",
          tower_name = "Poison Bolt",
          texture = sprites.tower_poisoned_arrow or sprites.orb_range,
          description = {
            "Takes all current stacks of poison and does double damage. then sets stacks to 0.",
          },
          hints = {
            { field = TowerStatField.DAMAGE, hint = UpgradeHint.GOOD },
          },
          on_accept = function(_, tower)
            ---@cast tower vibes.PoisonedArrowTower
            tower._tags.poison_bolt = true
          end,
        },
      },
    }
  end

  return Tower.get_levelup_reward(self)
end

---@type table<TowerStatField, table<Rarity, tower.UpgradeOption>>
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
}

---@type table<Rarity, tower.UpgradeOption[]>
local enhancements_by_rarity =
  TowerUtils.convert_enhancement_by_type_to_rarity(base_enhancements)

---@return table<TowerStatField, table<Rarity, tower.UpgradeOption>>
function PoisonedArrowTower:get_tower_stat_enhancements()
  return base_enhancements
end

---@return table<Rarity, tower.UpgradeOption[]>
function PoisonedArrowTower:get_upgrade_options()
  -- No improved enhancements logic for poison tower
  return enhancements_by_rarity
end

return PoisonedArrowTower
