local Spawn = require "vibes.enemy.spawn-entry"

---@class enemy.Wave : vibes.Class
---@field new fun(opts: enemy.Wave.Opts): enemy.Wave
---@field init fun(self: enemy.Wave, opts: enemy.Wave.Opts)
---@field spawns enemy.SpawnEntry[]
---@field start_time number
local Wave = class "enemy.Wave"

---@class enemy.Wave.Opts
---@field spawns enemy.SpawnEntry[]

---@param opts enemy.Wave.Opts
function Wave:init(opts)
  validate(opts, {
    spawns = List { Spawn },
  })

  self.spawns = opts.spawns
  self.start_time = 0
end

return Wave
