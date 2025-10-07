local Enemy = require "vibes.enemy.base"

---@class vibes.EnemyGoblin : vibes.Enemy
---@field new fun(opts: vibes.EnemyOptions): vibes.EnemyGoblin
---@field init fun(self: self, opts: vibes.EnemyOptions)
---@field animation vibes.SpriteAnimation
---@field _properties enemy.Properties
local EnemyGoblin = class("vibes.EnemyGoblin", { super = Enemy })
EnemyGoblin._properties =
  require("vibes.enemy.all-enemy-stats")[EnemyType.GOBLIN]

function EnemyGoblin:init(opts)
  Enemy.init(self, opts)
  self.stats_base.damage = Stat.new(5, 1)
end

return EnemyGoblin
