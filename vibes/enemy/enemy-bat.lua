local Enemy = require "vibes.enemy.base"
local asset = require "vibes.asset"

---@class vibes.EnemyBat : vibes.Enemy
---@field new fun(opts: vibes.EnemyOptions): vibes.EnemyBat
---@field init fun(self: self, opts: vibes.EnemyOptions)
---@field animation vibes.SpriteAnimation
---@field _properties enemy.Properties
local EnemyBat = class("vibes.EnemyBat", { super = Enemy })
EnemyBat._properties = require("vibes.enemy.all-enemy-stats")[EnemyType.BAT]

function EnemyBat:init(opts) Enemy.init(self, opts) end

return EnemyBat
