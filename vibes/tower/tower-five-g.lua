local Projectile = require "vibes.projectile"
local Tower = require "vibes.tower.base"

---@class vibes.TowerFiveG : vibes.Tower
---@field new fun(): vibes.TowerFiveG
---@field _enemies_hexed table<number, boolean>
local TowerFiveG = class("vibes.TowerFiveG", { super = Tower })

function TowerFiveG:init(opts)
  Tower.init(
    self,
    TowerStats.new {
      range = Stat.new(3, 1),
      damage = Stat.new(0, 1),
      attack_speed = Stat.new(1, 1),
      enemy_targets = Stat.new(1, 1),
    },
    Asset.sprites.tower_dj,
    { kind = TowerKind.SHOOTER, element_kind = ElementKind.AIR }
  )

  local Hooks = require "vibes.hooks"
  self.hooks = Hooks.new {
    after_level_end = function(self, level) self._enemies_hexed = {} end,
  }

  self.transformation_duration = 5 -- Duration in seconds for transformation
  self._enemies_hexed = {}
end

function TowerFiveG:get_projectile_starting_position()
  return Position.from_cell(self.cell):add(
    Position.new(
      0 + math.random(-10, 10),
      -Config.grid.cell_size * 0.5 + math.random(-10, 10)
    )
  )
end

---@param initial_target vibes.Enemy
function TowerFiveG:_create_projectile(initial_target)
  SoundManager:play_shoot_arrow(1.5)

  local enemy_position = initial_target.center:clone()
  local dst = enemy_position

  return Projectile.new {
    src = self:get_projectile_starting_position(),
    dst = dst,
    speed = function() return TrueRandom:decimal_range(10, 12) end,
    durability = self:get_durability(),
    texture = Asset.sprites.projectile_arrow,
    on_collide = function(_, enemy) self:transform_enemy(enemy) end,
  }
end

--- Create a projectile when attacking
---@param target vibes.Enemy
---@return vibes.Projectile
function TowerFiveG:attack(target) return self:_create_projectile(target) end

function TowerFiveG:find_targets()
  local _, all_enemies = Tower.find_targets(self)

  local valid_targets = {}
  for _, enemy in ipairs(all_enemies) do
    if not self._enemies_hexed[enemy.id] then
      table.insert(valid_targets, enemy)
    end
  end

  return valid_targets, all_enemies
end

function TowerFiveG:transform_enemy(enemy)
  -- Check for one-shot rule: if already transformed, cannot transform again
  if self._enemies_hexed[enemy.id] then
    return
  end

  self._enemies_hexed[enemy.id] = true

  -- Initialize transformation if not already
  if not enemy.statuses.hexed then
    enemy.statuses.hexed = true
    enemy.statuses.hexed_timer = 0

    local original_animation = enemy.animation
    enemy.animation = Asset.animations.frog_walk

    -- Set one-shot timer to revert after 3 seconds
    Timer.oneshot_gametime(1000, function()
      if enemy.statuses.hexed then
        enemy.statuses.hexed = false
        enemy.animation = original_animation -- Restore original animation
        enemy.statuses.hexed = false -- Mark as one-shot, cannot transform again
      end
    end)
  end
end

return TowerFiveG
