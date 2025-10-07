local Level = require "vibes.level"
local Random = require "vibes.engine.random"
local SpawnEntry = require "vibes.enemy.spawn-entry"
local Wave = require "vibes.enemy.wave"

local BASE_WAVE_COUNT = 1
local BASE_HEALTH = 100000
local LEVEL_MULTIPLIER = 1.1
local random = Random.new { name = "level-infinite" }

local function to_list(t)
  local list = {}
  for _, v in pairs(t) do
    table.insert(list, v)
  end
  return list
end

---@param level vibes.Level
---@param remaining_health number
local function make_random_spawn(level, wave_idx, remaining_health)
  local enemy_type = random:of_enum(EnemyType)
  local health = math.floor(
    math.max(15000, remaining_health * random:decimal_range(0.2, 0.6))
  )
  local path_ids = to_list(level.paths)
  local path = random:of_list(path_ids)

  local spawn = SpawnEntry.new {
    path = path,
    level_idx = level.level_idx,
    spawn = {
      path_id = path.id,
      type = enemy_type,
      hp = health,
      delay = wave_idx - 1,
      time_betwixt = random:decimal_range(0.15, 0.45),
    },
  }

  logger.trace(
    "infinite level(%d): spawned %s with %d health",
    level.level_idx,
    enemy_type,
    health
  )
  return spawn
end

---@class (exact) vibes.Level.Infinite.Opts
---@field level number
---@field level_data_path string
---
---@class (exact) vibes.Level.Infinite : vibes.Level
---@field new fun(opts: vibes.Level.Infinite.Opts): vibes.Level.Infinite
---@field init fun(self: vibes.Level.Infinite, opts: vibes.Level.Infinite.Opts)
local LevelInfinite = class("vibes.Level.infinite", { super = Level })

--- @param opts vibes.Level.Infinite.Opts
function LevelInfinite:init(opts)
  self.name = "infinite-" .. opts.level .. "-" .. opts.level_data_path

  Level:init_map_data_from_file(opts.level_data_path)
  self.level_idx = opts.level

  local wave_count = BASE_WAVE_COUNT + math.floor(opts.level / 5)
  local waves = {}

  for i = 1, wave_count do
    local health_for_level = BASE_HEALTH
      * (LEVEL_MULTIPLIER ^ (opts.level + i - 1))
    local spawns = {}

    while health_for_level > 0 do
      local spawn = make_random_spawn(self, i, health_for_level)
      table.insert(spawns, spawn)
      health_for_level = health_for_level - spawn.hp
    end

    table.insert(
      waves,
      Wave.new {
        spawns = spawns,
      }
    )
  end

  self.waves = waves
end

function LevelInfinite:on_start() print "Start hook" end
function LevelInfinite:on_draw() print "Draw hook" end
function LevelInfinite:on_play() print "Play hook" end
function LevelInfinite:on_spawn() end
function LevelInfinite:on_wave() end
function LevelInfinite:on_end() print "End hook" end
function LevelInfinite:on_complete() print "Complete hook" end
function LevelInfinite:on_game_over() print "Game over hook" end

return LevelInfinite
