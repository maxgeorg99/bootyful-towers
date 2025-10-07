local Enemy = require "vibes.enemy.base"

---@class enemy.SpawnEntry
---@field new fun(opts: enemy.SpawnOpts): enemy.SpawnEntry
---@field init fun(self: self, opts: enemy.SpawnOpts)
---@field path vibes.Path
---@field remaining_spawns number
---@field last_spawn_time number
---@field delay number
---@field level_idx number
---@field _enemy_health number
---@field time_betwixt number
local SpawnEntry = class "enemy.SpawnEntry"

SpawnEntry.enemy_classes = {
  require "vibes.enemy.enemy-bat",
  require "vibes.enemy.enemy-goblin",
  require "vibes.enemy.enemy-mine-goblin",
  require "vibes.enemy.enemy-orc",
  require "vibes.enemy.enemy-wolf",

  -- Elites
  require "vibes.enemy.enemy-elite-bat",
  require "vibes.enemy.enemy-elite-snail",
  require "vibes.enemy.enemy-orc-chief",
  require "vibes.enemy.enemy-orc-wheeler",
  require "vibes.enemy.enemy-elite-orc-shaman",

  -- Bosses
  require "vibes.enemy.enemy-boss-orca",
  require "vibes.enemy.enemy-boss-wyvern",
  require "vibes.enemy.enemy-boss-tauntoise",
  require "vibes.enemy.enemy-boss-king",
  require "vibes.enemy.enemy-boss-cat-tatus",
}

---@type table<EnemyType, vibes.Enemy>
local types_to_enemy = {}
for _, enemy_class in ipairs(SpawnEntry.enemy_classes) do
  assert(
    enemy_class._properties.enemy_type,
    "enemy_type is required: " .. tostring(enemy_class)
  )

  assert(
    not types_to_enemy[enemy_class._properties.enemy_type],
    "Duplicate enemy type"
  )
  types_to_enemy[enemy_class._properties.enemy_type] = enemy_class
end

---@class enemy.SpawnOpts
---@field path vibes.Path
---@field spawn vibes.LevelData.Spawn
---@field level_idx number

---@param opts enemy.SpawnOpts
function SpawnEntry:init(opts)
  validate(opts, {
    path = Path,
    spawn = "table",
    level_idx = "number",
  })

  validate(opts.spawn, {
    type = EnemyType,
    hp = "number",
    delay = "number",
    time_betwixt = "number",
  })

  self.path = opts.path
  self.type = opts.spawn.type
  self.hp = opts.spawn.hp
  self.level_idx = opts.level_idx

  self.delay = opts.spawn.delay / 1000
  self.time_betwixt = opts.spawn.time_betwixt / 1000

  self.last_spawn_time = 0
  local base_health_multiplier = 1
    + (self.level_idx == 0 and 0 or 1.6 ^ (self.level_idx - 1))
  local enemy_health = types_to_enemy[self.type]._properties.health
    * base_health_multiplier
  local enemies = math.ceil(self.hp / enemy_health)

  self.remaining_spawns = enemies
  self._enemy_health = enemy_health
end

---@param now number
---@return vibes.Enemy
function SpawnEntry:spawn_one_enemy(now)
  self.remaining_spawns = self.remaining_spawns - 1
  self.last_spawn_time = now

  local enemy_class = types_to_enemy[self.type]
  local enemy = Enemy.spawn(enemy_class, {
    path = self.path,
    enemy_level = State.levels.current_level_idx,
    health = self._enemy_health,
  })
  enemy.position = Position.from_cell(self.path.cells[1])
  enemy.pathing_state.path_index = 1
  enemy.pathing_state.percent_complete = 0
  enemy.pathing_state.segment_complete = 0

  return enemy
end

return SpawnEntry
