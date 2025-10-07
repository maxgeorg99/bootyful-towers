local Wave = require "vibes.enemy.wave"

---@class vibes.Spawner : vibes.Class
---@field new fun(opts: _): vibes.Spawner
---@field init fun(self: vibes.Spawner, opts: _)
---@field done_count number
---@field last_spawn_time number
local Spawner = class "vibes.Spawner"

function Spawner:init(_)
  self.done_count = 0
  self.last_spawn_time = 0
end

---@param wave enemy.Wave
---@param spawn enemy.SpawnEntry
---@param now number
function Spawner:_spawn_enemy_at_path(wave, spawn, now)
  local enemy = spawn:spawn_one_enemy(now)

  -- I feel like we could condense this into a single line with the EventBus,
  -- COPIED FROM enemy.SpawnEntry:spawn_one_enemy
  table.insert(State.enemies, enemy)
  State.levels:get_current_level():on_spawn(wave, enemy)
  EventBus:emit_enemy_spawned { enemy = enemy }

  if spawn.remaining_spawns == 0 then
    self.done_count = self.done_count + 1
  end

  return enemy
end

function Spawner:update()
  local now = require("vibes.engine.time").now()
  for _, spawn in ipairs(self.wave.spawns) do
    -- Schedule spawns strictly based on time_betwixt so spacing is consistent
    local next_spawn_time = spawn.last_spawn_time + spawn.time_betwixt
    while spawn.remaining_spawns > 0 and next_spawn_time <= now do
      self:_spawn_enemy_at_path(self.wave, spawn, next_spawn_time)
      next_spawn_time = spawn.last_spawn_time + spawn.time_betwixt
    end
  end
end

function Spawner:reset() self.done_count = 0 end

---@param wave enemy.Wave
function Spawner:spawn_wave(wave)
  assert(Wave.is(wave), "wave must be a enemy.Wave")

  State.levels:get_current_level():on_wave(wave)

  self.wave = wave
  wave.start_time = require("vibes.engine.time").now()

  for _, spawn in ipairs(wave.spawns) do
    -- Ensure the first spawn occurs exactly at start_time + delay
    -- By setting last_spawn_time to (start - time_betwixt + delay),
    -- the first computed next_spawn_time equals start_time + delay
    spawn.last_spawn_time = wave.start_time + spawn.delay - spawn.time_betwixt
  end
end

---@return boolean
function Spawner:is_done()
  -- If there's no wave, we're done ?
  return self.done_count == #self.wave.spawns
end

return Spawner
