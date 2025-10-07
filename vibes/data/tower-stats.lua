---@class tower.Stats : vibes.Class
---@field new fun(opts: tower.Stats.Opts): tower.Stats
---@field init fun(self: tower.Stats, opts: tower.Stats.Opts)
---@field range vibes.Stat
---@field damage vibes.Stat
---@field attack_speed vibes.Stat
---@field critical vibes.Stat
---@field enemy_targets vibes.Stat
---@field durability vibes.Stat
---@field aoe vibes.Stat
local Stats = class "tower.stats"

---@class tower.Stats.Opts
---@field range vibes.Stat
---@field damage vibes.Stat
---@field attack_speed vibes.Stat
---@field critical? vibes.Stat
---@field enemy_targets vibes.Stat
---@field durability? vibes.Stat
---@field aoe? vibes.Stat

function Stats:init(opts)
  -- TODO: Poison, Fire, etc.

  opts.durability = opts.durability or Stat.new(1, 1)
  opts.critical = opts.critical or Stat.new(0.05, 1)
  opts.aoe = opts.aoe or Stat.new(0, 1)

  validate(opts, {
    range = Stat,
    damage = Stat,
    attack_speed = Stat,
    critical = Stat,
    enemy_targets = Stat,
    durability = Stat,
    aoe = Stat,
  })

  self.range = opts.range
  self.damage = opts.damage
  self.attack_speed = opts.attack_speed
  self.critical = opts.critical
  self.enemy_targets = opts.enemy_targets
  self.durability = opts.durability
  self.aoe = opts.aoe
end

function Stats:clone()
  return Stats.new {
    range = self.range:clone(),
    damage = self.damage:clone(),
    attack_speed = self.attack_speed:clone(),
    critical = self.critical:clone(),
    enemy_targets = self.enemy_targets:clone(),
    durability = self.durability:clone(),
    aoe = self.aoe:clone(),
  }
end

return Stats
