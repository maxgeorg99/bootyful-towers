local Enemy = require "vibes.enemy.base"

local KingState = {
  ONE = "one",
  SPAWN_ONE = "spawn_one",
  TWO = "two",
  SPAWN_TWO = "spawn_two",
  THREE = "three",
  SPAWN_THREE = "spawn_three",
  FOUR = "four",
}

local WAIT_STEP_TIME = 0.5
local SPAWN_ONE_TIME_STEP = 0.25
local SPAWN_TWO_TIME_STEP = 0.2
local SPAWN_THREE_TIME_STEP = 0.1

---@class vibes.EnemyKing : vibes.Enemy
---@field new fun(path: vibes.Path): vibes.EnemyKing
---@field init fun(self: vibes.EnemyKing, path: vibes.Path)
---@field _properties enemy.Properties
---@field last_step_wait number
---@field spawn_time_remaining number
---@field spawn_count number
---@field states string
local EnemyKing = class("vibes.EnemyKing", { super = Enemy })
EnemyKing._properties = require("vibes.enemy.all-enemy-stats")[EnemyType.KING]

---@param opts vibes.EnemyOptions
function EnemyKing:init(opts)
  Enemy.init(self, opts)

  self.last_step_wait = WAIT_STEP_TIME
  self.spawn_time_remaining = WAIT_STEP_TIME
  self.spawn_count = 0
  self.states = KingState.ONE
end

function EnemyKing:update(dt)
  -- Call parent Enemy update to ensure center and other properties are set
  Enemy.update(self, dt)

  self.last_step_wait = self.last_step_wait - dt
  if self.last_step_wait > 0 then
    return
  end

  if
    self.states == KingState.ONE
    or self.states == KingState.TWO
    or self.states == KingState.THREE
    or self.states == KingState.FOUR
  then
    self:step_move_to(self:get_path_node(), dt)
  elseif self.states == KingState.SPAWN_ONE then
    self:spawn_one(dt)
  elseif self.states == KingState.SPAWN_TWO then
    self:spawn_two(dt)
  elseif self.states == KingState.SPAWN_THREE then
    self:spawn_three(dt)
  else
    error "WTF"
  end
end

--- @return vibes.Cell
function EnemyKing:get_path_node()
  if self.states == KingState.ONE then
    return self.pathing_state.path.cells[2]
  elseif self.states == KingState.TWO then
    return self.pathing_state.path.cells[3]
  elseif self.states == KingState.THREE then
    return self.pathing_state.path.cells[4]
  elseif self.states == KingState.FOUR then
    return self.pathing_state.path.cells[5]
  end
  error "bubbly the greatest drink of all"
end

---@param to_cell vibes.Cell
---@param _dt number
function EnemyKing:step_move_to(to_cell, _dt)
  local destination = Position.from_cell(to_cell)
  local to = destination:sub(self.position)
  local to_len = to:magnitude()
  local dir = to:normalize()

  local change = dir:scale(0.25 * Config.grid.cell_size)
  if change:magnitude() > to_len or to_len == 0 then
    self.position = destination
    self:next_state()
  else
    self.position = self.position:add(change)
  end
  self.last_step_wait = WAIT_STEP_TIME
end

function EnemyKing:next_state()
  print "netx state"
  if self.states == KingState.ONE then
    self.states = KingState.SPAWN_ONE
    self.spawn_time_remaining = SPAWN_ONE_TIME_STEP
    self.spawn_count = 100
  elseif self.states == KingState.SPAWN_ONE then
    self.states = KingState.TWO
  elseif self.states == KingState.TWO then
    self.states = KingState.SPAWN_TWO
    self.spawn_count = 200
  elseif self.states == KingState.SPAWN_TWO then
    self.states = KingState.THREE
  elseif self.states == KingState.THREE then
    self.states = KingState.SPAWN_THREE
    self.spawn_count = 300
  elseif self.states == KingState.SPAWN_THREE then
    self.states = KingState.FOUR
  elseif self.states == KingState.FOUR then
    State:damage_player_health(State.player.health)
  end
end

---@param level_idx number
---@param path vibes.Path
---@param location vibes.Position
---@param enemy_type EnemyType
local spawn = function(level_idx, path, location, enemy_type)
  local now = require("vibes.engine.time").now()

  local SpawnEntry = require "vibes.enemy.spawn-entry"
  local spawn_entry = SpawnEntry.new {
    path = path,
    level_idx = level_idx,
    spawn = {
      type = enemy_type,
      hp = 1,
      delay = 0,
      path_id = path.id,
      -- Use milliseconds to match level JSON schema (converted in SpawnEntry)
      time_betwixt = 350,
    },
  }

  local enemy = spawn_entry:spawn_one_enemy(now)
  enemy.cell = Cell.from_position(location)
  enemy.position = location
end

--- @param dt number
function EnemyKing:spawn_one(dt)
  self.spawn_time_remaining = self.spawn_time_remaining - dt
  if self.spawn_time_remaining > 0 then
    return
  end

  self.spawn_time_remaining = SPAWN_ONE_TIME_STEP
  self.spawn_count = self.spawn_count - 1

  -- Generate a random position around the king
  local random_offset_x = math.random(-50, 50)
  local random_offset_y = math.random(-50, 50)
  local spawn_position = Position.new(
    self.position.x + random_offset_x,
    self.position.y + random_offset_y
  )

  spawn(
    self.enemy_level,
    self.pathing_state.path,
    spawn_position,
    EnemyType.ORC
  )

  if self.spawn_count <= 0 then
    self:next_state()
  end
end

local spawn_two = {
  EnemyType.ORC,
  EnemyType.GOBLIN,
  EnemyType.MINE_GOBLIN,
}

--- @param dt number
function EnemyKing:spawn_two(dt)
  self.spawn_time_remaining = self.spawn_time_remaining - dt
  if self.spawn_time_remaining > 0 then
    return
  end

  self.spawn_time_remaining = SPAWN_TWO_TIME_STEP
  self.spawn_count = self.spawn_count - 1

  -- Generate a random position around the king
  local random_offset_x = math.random(-75, 75)
  local random_offset_y = math.random(-75, 75)
  local spawn_position = Position.new(
    self.position.x + random_offset_x,
    self.position.y + random_offset_y
  )

  local enemy = spawn_two[math.random(1, #spawn_two)]

  spawn(self.enemy_level, self.pathing_state.path, spawn_position, enemy)

  if self.spawn_count <= 0 then
    self:next_state()
  end
end

--- @param dt number
function EnemyKing:spawn_three(dt)
  self.spawn_time_remaining = self.spawn_time_remaining - dt
  if self.spawn_time_remaining > 0 then
    return
  end

  self.spawn_time_remaining = SPAWN_THREE_TIME_STEP
  self.spawn_count = self.spawn_count - 1

  -- Generate a random position around the king
  local random_offset_x = math.random(-150, 150)
  local random_offset_y = math.random(-150, 150)
  local spawn_position = Position.new(
    self.position.x + random_offset_x,
    self.position.y + random_offset_y
  )

  local enemy = spawn_two[math.random(1, #spawn_two)]

  spawn(self.enemy_level, self.pathing_state.path, spawn_position, enemy)

  if self.spawn_count <= 0 then
    self:next_state()
  end
end

return EnemyKing
