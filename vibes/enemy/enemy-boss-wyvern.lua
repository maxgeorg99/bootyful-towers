local Enemy = require "vibes.enemy.base"

---@class vibes.EnemyWyvern : vibes.Enemy
---@field new fun(path: vibes.Path): vibes.EnemyWyvern
---@field init fun(self: vibes.EnemyWyvern, path: vibes.Path)
---@field _properties enemy.Properties
local EnemyWyvern = class("vibes.EnemyWyvern", { super = Enemy })
EnemyWyvern.init = Enemy.init

EnemyWyvern._properties =
  require("vibes.enemy.all-enemy-stats")[EnemyType.WYVERN]

return EnemyWyvern
