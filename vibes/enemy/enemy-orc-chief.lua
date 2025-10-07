-- ORC CHIEF IS UNSLOWABLE
-- CANNOT BE SLOWED BY ANYTHING! CAN STILL BE SPED UP THOUGH!

local Enemy = require "vibes.enemy.base"

---@class vibes.EnemyOrcChief : vibes.Enemy
---@field new fun(opts: vibes.EnemyOptions): vibes.EnemyOrcChief
---@field init fun(self: self, opts: vibes.EnemyOptions)
---@field animation vibes.SpriteAnimation
---@field _properties enemy.Properties
local EnemyOrcChief = class("vibes.EnemyOrcChief", { super = Enemy })
EnemyOrcChief._properties =
  require("vibes.enemy.all-enemy-stats")[EnemyType.ORC_CHIEF]

function EnemyOrcChief:init(opts) Enemy.init(self, opts) end

function EnemyOrcChief:get_speed()
  return math.max(Enemy.get_speed(self), self._properties.speed)
end

return EnemyOrcChief
