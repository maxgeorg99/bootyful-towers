local Enemy = require "vibes.enemy.base"

---@class vibes.EnemyMineGoblin : vibes.Enemy
---@field new fun(opts: vibes.EnemyOptions): vibes.EnemyMineGoblin
---@field init fun(self: self, opts: vibes.EnemyOptions)
---@field _properties enemy.Properties
local EnemyMineGoblin = class("vibes.EnemyMineGoblin", { super = Enemy })
EnemyMineGoblin.init = Enemy.init
EnemyMineGoblin._properties =
  require("vibes.enemy.all-enemy-stats")[EnemyType.MINE_GOBLIN]

return EnemyMineGoblin
