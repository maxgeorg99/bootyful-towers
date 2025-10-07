local Enemy = require "vibes.enemy.base"

---@class vibes.EnemyOrcShaman.Properties : enemy.Properties
---@field shaman_heal_amount number
---@field shaman_heal_range_in_cells number

---@class vibes.EnemyOrcShaman : vibes.Enemy
---@field new fun(opts: vibes.EnemyOptions): vibes.EnemyOrcShaman
---@field init fun(self: vibes.EnemyOrcShaman, opts: vibes.EnemyOptions)
---@field _properties vibes.EnemyOrcShaman.Properties
local EnemyOrcShaman = class("vibes.EnemyOrcShaman", { super = Enemy })
EnemyOrcShaman._properties =
  require("vibes.enemy.all-enemy-stats")[EnemyType.ORC_SHAMAN]

function EnemyOrcShaman:init(opts) Enemy.init(self, opts) end

function EnemyOrcShaman:update(dt)
  Enemy.update(self, dt)

  ---@type vibes.Enemy[]
  local enemies = {}
  for _, enemy in ipairs(State.enemies) do
    local distance = self.position:distance(enemy.position)
      / Config.grid.cell_size
    if
      enemy ~= self
      and distance <= self._properties.shaman_heal_range_in_cells
    then
      table.insert(enemies, enemy)
    end
  end

  -- Health enemies for 5 HP per second
  for _, enemy in ipairs(enemies) do
    enemy.health = math.min(
      enemy.health + self._properties.shaman_heal_amount * dt,
      enemy.max_health
    )
  end
end

return EnemyOrcShaman
