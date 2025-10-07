-- orca eats enemies
-- orca gains health & damage when eating enemies

---@class vibes.EnemyOrca.Properties : enemy.Properties
---@field orca_boss_eat_multiplier number
---@field orca_boss_low_health_multiplier number
---@field orca_boss_low_health_threshold number

local Enemy = require "vibes.enemy.base"

---@class vibes.EnemyOrca : vibes.Enemy
---@field new fun(path: vibes.Path): vibes.EnemyOrca
---@field init fun(self: vibes.EnemyOrca, path: vibes.Path)
---@field super vibes.Enemy
---@field last_cell vibes.Cell
---@field entered_into_special_cell number?
---@field _properties vibes.EnemyOrca.Properties
local EnemyOrca = class("vibes.EnemyOrca", { super = Enemy })

EnemyOrca._properties = require("vibes.enemy.all-enemy-stats")[EnemyType.ORCA]

---@param opts vibes.EnemyOptions
function EnemyOrca:init(opts)
  Enemy.init(self, opts)

  self.entered_into_special_cell = nil
  self.original_speed = self.speed
end

function EnemyOrca:get_speed()
  if self.entered_into_special_cell then
    return 0
  end

  return self.super.get_speed(self)
end

function EnemyOrca:update(dt)
  -- if self.cell.row == 1 then
  --   SoundManager:play_boss_music()
  -- end

  local health_percentage = self.health / self.max_health
  if
    health_percentage < EnemyOrca._properties.orca_boss_low_health_threshold
  then
    self.stats_base.speed.mult =
      EnemyOrca._properties.orca_boss_low_health_multiplier
  else
    self.stats_base.speed.mult = 1
  end

  Enemy.update(self, dt)

  if health_percentage < 0.8 then
    local GameFunctions = require "vibes.data.game-functions"
    local enemies = GameFunctions.enemies_within(self.position, 10)

    local enemies_to_eat = {}
    for _, enemy in ipairs(enemies) do
      if enemy ~= self then
        table.insert(enemies_to_eat, enemy)
      end
    end

    table.sort(
      enemies_to_eat,
      function(a, b)
        return a.position:distance(self.position)
          < b.position:distance(self.position)
      end
    )

    local enemy = table.remove(enemies_to_eat, 1)
    if enemy then
      self.health = math.min(
        self.health
          + enemy.health * EnemyOrca._properties.orca_boss_eat_multiplier,
        self.max_health
      )

      EventBus:emit_enemy_death {
        enemy = enemy,
        position = enemy.position,
        kind = DamageKind.ORCA_BOSS_EAT,
      }
    end
  end
end

return EnemyOrca
