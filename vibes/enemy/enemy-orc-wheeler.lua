local Enemy = require "vibes.enemy.base"

---@class enemy.OrcWheelerProperties : enemy.Properties
---@field orc_wheeler_explosion_radius number Number of cells in the explosion radius

---@class vibes.EnemyOrcWheeler : vibes.Enemy
---@field new fun(opts: vibes.EnemyOptions): vibes.EnemyOrcWheeler
---@field init fun(self: self, opts: vibes.EnemyOptions)
---@field animation vibes.SpriteAnimation
---@field _properties enemy.OrcWheelerProperties
local EnemyOrcWheeler = class("vibes.EnemyOrcWheeler", { super = Enemy })

---@diagnostic disable-next-line: assign-type-mismatch
EnemyOrcWheeler._properties =
  require("vibes.enemy.all-enemy-stats")[EnemyType.ORC_WHEELER]

function EnemyOrcWheeler:init(opts) Enemy.init(self, opts) end

EventBus:listen_enemy_reached_end(function(event)
  if EnemyOrcWheeler.is(event.enemy) then
    GameAnimationSystem:play_explosion(event.enemy.position)
    GameAnimationSystem:play_fire(event.enemy.position)
  end
end)

EventBus:listen_enemy_death(function(event)
  if EnemyOrcWheeler.is(event.enemy) then
    GameAnimationSystem:play_explosion(event.enemy.position)
    GameAnimationSystem:play_fire(event.enemy.position)

    local GameFunctions = require "vibes.data.game-functions"
    local enemies = GameFunctions.enemies_within(
      event.position,
      EnemyOrcWheeler._properties.orc_wheeler_explosion_radius
        * Config.grid.cell_size
    )
    for _, enemy in ipairs(enemies) do
      State:damage_enemy {
        enemy = enemy,
        damage = event.enemy:get_damage(),
        kind = DamageKind.ORC_WHEELER_EXPLOSION,
      }
    end
  end
end)

return EnemyOrcWheeler
