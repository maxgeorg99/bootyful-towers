local Enemy = require "vibes.enemy.base"

---@class vibes.EnemyBatBoss : vibes.Enemy
---@field new fun(opts: vibes.EnemyOptions): vibes.EnemyBatBoss
---@field init fun(self: self, opts: vibes.EnemyOptions)
---@field _properties enemy.Properties
local EnemyBatBoss = class("vibes.EnemyBatBoss", { super = Enemy })
EnemyBatBoss._properties =
  require("vibes.enemy.all-enemy-stats")[EnemyType.BAT_ELITE]

function EnemyBatBoss:init(opts)
  Enemy.init(self, opts)
  self.stats_base.damage = Stat.new(0.5, 1)
end

return EnemyBatBoss
