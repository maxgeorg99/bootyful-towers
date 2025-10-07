local Enemy = require "vibes.enemy.base"

---@class vibes.EnemyOrc : vibes.Enemy
---@field new fun(opts: vibes.EnemyOptions): vibes.EnemyOrc
---@field init fun(self: self, opts: vibes.EnemyOptions)
---@field _properties enemy.Properties
local EnemyOrc = class("vibes.EnemyOrc", { super = Enemy })
EnemyOrc.init = Enemy.init
EnemyOrc._properties = require("vibes.enemy.all-enemy-stats")[EnemyType.ORC]

return EnemyOrc
