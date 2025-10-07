local Enemy = require "vibes.enemy.base"

---@class vibes.EnemyWolf : vibes.Enemy
---@field new fun(opts: vibes.EnemyOptions): vibes.EnemyWolf
---@field init fun(self: self, opts: vibes.EnemyOptions)
---@field _properties enemy.Properties
local EnemyWolf = class("vibes.EnemyWolf", { super = Enemy })
EnemyWolf.init = Enemy.init
EnemyWolf._properties = require("vibes.enemy.all-enemy-stats")[EnemyType.WOLF]

return EnemyWolf
