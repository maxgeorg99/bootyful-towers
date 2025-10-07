-- TODO: This is more just like shadow stuff? But I'm not even sure it needs a new file anymore. It's Ok for now tho.
local drawing = require "vibes.drawing"

---@class vibes.Enemy.PathingState
---@field path vibes.Path
---@field path_index number The current path index
---@field percent_complete number
---@field segment_complete number

---@param path vibes.Path
---@return vibes.Enemy.PathingState
local new_pathing_state = function(path)
  return {
    path = path,
    path_index = 1,
    percent_complete = 0,
    segment_complete = 0,
  }
end

---@class (exact) enemy.Properties
--
-- Stat Properties
---@field health number
---@field speed number
---@field damage number?
---@field shield number?
---@field block number?
--
-- Enemy Properties
---@field enemy_type string
---@field gold_reward number
---@field xp_reward number
---@field animation vibes.SpriteAnimation
---@field texture vibes.Texture

---@class enemy.Options
---@field path vibes.Path
---@field enemy_level number: The level of the enemy
---@field health number?: The health of the enemy
---@field origin vibes.Position?: The origin of the enemy

---@class vibes.EnemyOptions : enemy.Properties, enemy.Options

---@class vibes.Enemy.Statuses
---@field sludged boolean: Whether the enemy is affected by sludged status
---@field poison_pool boolean: Whether the enemy is affected by poison pool status
---@field burnt boolean: Whether the enemy is affected by burnt status
---@field poisoned boolean: Whether the enemy is affected by poisoned status
---@field hexed boolean: Whether the enemy is affected by hexed status
---@field hexed_timer? number: The timer for the hexed status
---@field taunting boolean: Whether the enemy is taunting
---@field wet boolean: Whether the enemy is affected by wet status

---@class (exact) vibes.Enemy : vibes.Class, enemy.Properties
---@field new fun(opts: vibes.EnemyOptions): vibes.Enemy
---@field init fun(self: vibes.Enemy, opts: vibes.EnemyOptions)
---@field _properties enemy.Properties
---@field status EnemyStatus
---@field statuses vibes.Enemy.Statuses: Status effects currently affecting the enemy
---@field max_health number: Maximum health capacity of the enemy
---@field stats_base enemy.Stats: Stats of the enemy
---@field stats_manager enemy.StatsManager: Stats manager of the enemy
---@field cell vibes.Cell: Cell of the enemy
---@field position vibes.Position: Position of the enemy
---@field center vibes.Position: Center of the enemy
---@field pathing_state vibes.Enemy.PathingState: Pathing state of the enemy
---@field texture vibes.Texture: Texture of the enemy
---@field animation vibes.SpriteAnimation?: Animation of the enemy
---@field gold_reward number: Amount of gold rewarded when defeated
---@field xp_reward number
---@field last_damage_time number
---@field hit_flash boolean
---@field last_dot_tick number
---@field flipped boolean Whether the enemy is flipped
---@field enemy_level number
---@field origin vibes.Position?: Origin of the enemy
---@field scale number: Visual scale multiplier for drawing
---@field scale_x number? Scale multiplier for x axis
---@field scale_y number? Scale multiplier for y axis
---@field physical_width number: Physical width for collision detection
---@field physical_height number: Physical height for collision detection
---@field frozen boolean: Whether the enemy is frozen
---@field turn_delay_timer number?: Timer for turn delay from Leaky Stein card
--
--- Elemental Stats
---@field fire_stacks number
---@field fire_stack_sources table<vibes.Tower, number> Track which towers caused fire stacks for XP distribution
---@field poison_stacks number
---@field poison_stack_sources table<vibes.Tower, number>
---@field blood_stacks number
---@field blood_stack_sources table<vibes.Tower, number>
--
-- Public Methods
---@field spawn fun(cls: vibes.Enemy, opts: enemy.Options): vibes.Enemy
---@field get_damage fun(self: vibes.Enemy): number
---@field get_speed fun(self: vibes.Enemy): number
---@field get_shield fun(self: vibes.Enemy): number
---@field get_shield_capacity fun(self: vibes.Enemy): number
---@field update_position fun(self: vibes.Enemy, position: vibes.Position): boolean Whether the position was updated
---@field freeze fun(self: vibes.Enemy)
---@field unfreeze fun(self: vibes.Enemy)
local Enemy = class("vibes.enemy", { abstract = { _properties = true } })

--- Creates a new Enemy
---@param opts vibes.EnemyOptions
function Enemy:init(opts)
  validate(opts, {
    enemy_level = "number",
    enemy_type = "string",
    health = "number",
    speed = "number",
    path = Path,
    texture = "userdata",
    gold_reward = "number",
    xp_reward = "number",
    animation = "table?",
    origin = "table?",
  })

  self.enemy_level = opts.enemy_level
  self.enemy_type = opts.enemy_type
  self:update_position(Position.from_cell(opts.path.cells[1]))
  self.cell = Cell.from_position(self.position)

  -- TODO: This should just be an opt, not like this.
  self.stats_base = EnemyStats.new {
    block = Stat.new(opts.block or 0, 1),
    speed = Stat.new(opts.speed, 1),
    damage = Stat.new(opts.damage or 1, 1),
    shield = Stat.new(opts.shield or 0, 1),
    shield_capacity = Stat.new(
      math.max(opts.shield or 0, opts.shield_capacity or 0),
      1
    ),
  }

  self.stats_manager =
    require("vibes.data.enemy-stats-manager").new { enemy = self }

  self.health = opts.health
  self.max_health = opts.health
  self.status = EnemyStatus.ALIVE
  self.statuses = {
    sludged = false,
    poison_pool = false,
    burnt = false,
    poisoned = false,
    hexed = false,
    hexed_timer = 0,
    taunting = false,
    wet = false,
  }

  self.pathing_state = new_pathing_state(opts.path)

  self.texture = opts.texture
  self.animation = opts.animation
  self.gold_reward = opts.gold_reward
  self.xp_reward = opts.xp_reward
  self.origin = opts.origin

  self.last_dot_tick = 0

  -- Elemental Stats
  self.fire_stacks = 0
  self.fire_stack_sources = {}
  self.blood_stacks = 0
  self.blood_stack_sources = {}
  self.poison_stacks = 0
  self.poison_stack_sources = {}

  -- Initialize scale to default value
  self.scale = F.if_nil(opts.scale, 2)
  self.scale_x = F.if_nil(opts.scale_x, 1)
  self.scale_y = F.if_nil(opts.scale_y, 2)

  -- Initialize physical size based on texture dimensions
  self.physical_width = opts.texture:getWidth()
  self.physical_height = opts.texture:getHeight()

  -- Initialize center position
  self.origin = opts.origin
  if not self.origin then
    self.center = self.position:sub(Position.new(0, self.physical_height / 2))
  else
    self.center = self.position:sub(self.origin)
  end

  self.frozen = false
  self.turn_delay_timer = 0
end

function Enemy:update_position(position)
  if self.frozen then
    return false
  end
  self.position = position
  return true
end

function Enemy:freeze() self.frozen = true end

function Enemy:unfreeze() self.frozen = false end

function Enemy:_draw_texture()
  love.graphics.setColor(1, 1, 1)
  if self.animation then
    return self.animation:draw(self.position, self.scale, self.flipped)
  else
    return drawing.shifted_draw(
      self.texture,
      self.position,
      self.scale,
      self.flipped
    )
  end
end

local PYL_RARITY_MULTIPLIER = {
  [Rarity.COMMON] = 2,
  [Rarity.UNCOMMON] = 2.5,
  [Rarity.RARE] = 3,
  [Rarity.EPIC] = 3.5,
  [Rarity.LEGENDARY] = 5,
}

---@param cls vibes.Enemy
---@param opts enemy.Options
---@return vibes.Enemy
function Enemy.spawn(cls, opts)
  local props = table.copy(cls._properties)

  ---@cast props vibes.EnemyOptions

  props.path = opts.path
  props.enemy_level = opts.enemy_level
  props.health = opts.health or props.health
  if State.press_your_luck_card then
    print(
      "WE OUT HERE PRESSING: ",
      PYL_RARITY_MULTIPLIER[State.press_your_luck_card.rarity]
    )
    props.health = props.health
      * PYL_RARITY_MULTIPLIER[State.press_your_luck_card.rarity]
  end

  return cls.new(props)
end

function Enemy:get_block() return self.stats_manager.result.block.value end
function Enemy:get_damage() return self.stats_manager.result.damage.value end
function Enemy:get_speed() return self.stats_manager.result.speed.value end
function Enemy:get_shield() return self.stats_manager.result.shield.value end
function Enemy:get_shield_capacity()
  return self.stats_manager.result.shield_capacity.value
end

-- Hmmm, not sure i like this much, but it's OK start
function Enemy:set_shield(amount)
  self.stats_base.shield = Stat.new(amount, 1)
  self.stats_manager:update()
end

--- Updates a single enemy's state
---@param dt number
function Enemy:update(dt)
  self.stats_manager:update(dt)

  if self.poison_stacks > 0 then
    self.statuses.poisoned = true
  end

  if self.fire_stacks > 0 then
    self.statuses.burnt = true
  end

  if self.health <= 0 then
    error "Enemy:update called on dead enemy"
  end

  self.cell = Cell.from_position(self.position)

  local health = Stat.new(self.max_health, 1)
  self.max_health = health.value
  self.health = math.min(self.health, self.max_health)

  if self.statuses.hexed then
    self.statuses.hexed_timer = (self.statuses.hexed_timer or 0) + dt
  end

  -- Handle turn delay from Leaky Stein card
  if self.turn_delay_timer and self.turn_delay_timer > 0 then
    self.turn_delay_timer = self.turn_delay_timer - dt
    -- While delayed, skip movement but still update center position
    if not self.origin then
      self.center = self.position:sub(Position.new(0, self.physical_height / 2))
    else
      self.center = self.position:sub(self.origin)
    end
    return
  end

  -- TODO: Apply effects attached to enemy
  -- TODO: Apply effects from cell

  local path = self.pathing_state.path
  local current_cell = path.cells[self.pathing_state.path_index]
  local next_cell = path.cells[self.pathing_state.path_index + 1]

  if not next_cell then
    self.pathing_state.percent_complete = 1

    return EventBus:emit_enemy_reached_end {
      enemy = self,
    }
  end

  -- TODO(enemy): Calculate damage over time

  -- Calculate how far along the path we should move based on speed and dt
  local distance_to_move = self:get_speed() * dt

  -- Calculate direction vector between cells
  local current_pos = self.position
  local next_pos = Position.from_cell(next_cell)
  local seg_length =
    next_pos:sub(Position.from_cell(current_cell)):magnitude_squared()
  local remaining = next_pos:sub(current_pos)
  local remaining_len = remaining:magnitude_squared()

  -- TODO(TJD): Pathing stuff needs a update to be simpler to manage
  self.pathing_state.segment_complete = 1 - remaining_len / seg_length

  local dir_vector = remaining:normalize()
  if dir_vector.x < 0 then
    self.flipped = true
  else
    self.flipped = false
  end

  -- Calculate remaining distance to next cell
  local my_remaining = next_pos:sub(self.position)
  local length_remaining = my_remaining:magnitude()

  -- If we can reach the next cell this frame, move there and increment path index
  if length_remaining <= distance_to_move then
    self:update_position(next_pos)
    self.pathing_state.path_index = self.pathing_state.path_index + 1
    
    -- Check if Leaky Stein card is active and apply turn delay
    local has_leaky_stein = false
    for _, aura in ipairs(State.auras) do
      if aura._type == "aura.LeakyStein" and aura:is_active_on_enemy(self) then
        has_leaky_stein = true
        break
      end
    end
    
    if has_leaky_stein then
      self.turn_delay_timer = 0.3
    end
  else
    -- Otherwise move along path by distance_to_move
    local move = dir_vector:scale(distance_to_move)
    local new_position =
      Position.new(self.position.x + move.x, self.position.y + move.y)
    self:update_position(new_position)
  end

  self.pathing_state.percent_complete = self.pathing_state.path_index
    / #self.pathing_state.path.cells

  if not self.origin then
    self.center = self.position:sub(Position.new(0, self.physical_height / 2))
  else
    self.center = self.position:sub(self.origin)
  end
end

function Enemy:knockback(direction)
  local new_position =
    Position.new(self.position.x + direction.x, self.position.y + direction.y)
  self:update_position(new_position)
end

function Enemy:__tostring()
  return string.format("Enemy(%s): %s", self._type, self.position)
end

---@param tower vibes.Tower?
---@param amount number
function Enemy:apply_poison_stack(tower, amount)
  self.poison_stacks = (self.poison_stacks or 0) + amount

  if tower then
    self.poison_stack_sources[tower] = (self.poison_stack_sources[tower] or 0)
      + amount
  end
end

function Enemy:clear_poison_stacks()
  self.poison_stacks = 0
  self.poison_stack_sources = {}
end

function Enemy:clear_fire_stacks()
  self.fire_stacks = 0
  self.fire_stack_sources = {}
end

---@param tower vibes.Tower?
---@param amount number
function Enemy:apply_fire_stack(tower, amount)
  self.fire_stacks = (self.fire_stacks or 0) + amount

  if tower then
    -- Track which tower applied fire stacks for proper XP distribution
    self.fire_stack_sources[tower] = (self.fire_stack_sources[tower] or 0)
      + amount
  end
end

---@param tower vibes.Tower?
---@param amount number
function Enemy:apply_blood_stack(tower, amount)
  self.blood_stacks = (self.blood_stacks or 0) + amount
end

function Enemy:apply_damage(amount) end

--- Increase the physical size of the enemy by 10%
function Enemy:double_physical_size()
  self.physical_width = self.physical_width * 1.1
  self.physical_height = self.physical_height * 1.1
  self.scale = self.scale * 1.1
end

--- Draw the enemy (public method for background decoration)
function Enemy:draw() self:_draw_texture() end

return Enemy
