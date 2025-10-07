---@class enemy.Stats : vibes.Class
---@field new fun(opts: enemy.Stats.Opts): enemy.Stats
---@field init fun(self: enemy.Stats, opts: enemy.Stats.Opts)
---@field speed vibes.Stat
---@field damage vibes.Stat
---@field shield vibes.Stat
---@field shield_capacity vibes.Stat
---@field block vibes.Stat
local EnemyStats = class "vibes.EnemyStats"

---@class enemy.Stats.Opts
---@field speed vibes.Stat
---@field damage vibes.Stat
---@field shield vibes.Stat
---@field block vibes.Stat
---@field shield_capacity vibes.Stat

---@param opts enemy.Stats.Opts
---@return enemy.Stats
function EnemyStats:init(opts)
  opts.shield = F.if_nil(opts.shield, Stat.new(0, 0))
  opts.shield_capacity = F.if_nil(opts.shield_capacity, opts.shield:clone())

  validate(opts, {
    speed = Stat,
    damage = Stat,
    shield = Stat,
    shield_capacity = Stat,
    block = Stat,
  })

  self.speed = opts.speed
  self.damage = opts.damage
  self.shield = opts.shield
  self.shield_capacity = opts.shield_capacity
  self.block = opts.block
end

function EnemyStats:clone()
  return EnemyStats.new {
    speed = self.speed:clone(),
    damage = self.damage:clone(),
    shield = self.shield:clone(),
    shield_capacity = self.shield_capacity:clone(),
    block = self.block:clone(),
  }
end

return EnemyStats
