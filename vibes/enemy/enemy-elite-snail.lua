local Enemy = require "vibes.enemy.base"

---@class vibes.EnemySnail : vibes.Enemy
---@field new fun(opts: vibes.EnemyOptions): vibes.EnemySnail
---@field init fun(self: self, opts: vibes.EnemyOptions)
---@field _properties enemy.Properties
local EnemySnail = class("vibes.EnemySnail", { super = Enemy })
EnemySnail.init = Enemy.init
EnemySnail._properties = require("vibes.enemy.all-enemy-stats")[EnemyType.SNAIL]

return EnemySnail
