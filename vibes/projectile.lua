local FireParticle = require "vibes.particles.fire"
local Tower = require "vibes.tower.base"

local HIT_THRESHOLD = 1000
local DST_THRESHOLD = 50
local DST_THRESHOLD_SQUARED = 50 * 50

---@class projectile.Opts
---@field src vibes.Position
---@field dst (fun(self: vibes.Projectile): vibes.Position)|vibes.Position
---@field speed (fun(self: vibes.Projectile): number)|number
---@field durability number
---@field texture vibes.Texture
---@field fire boolean?
--
-- Callbacks
---@field on_collide fun(self: vibes.Projectile, enemy: vibes.Enemy)
---@field on_reached_target? fun(self: vibes.Projectile)

---@class (exact) vibes.Projectile: vibes.Class
---@field new fun(opts: projectile.Opts): self
---@field init fun(self: self, opts: projectile.Opts)
---@field src vibes.Position
---@field angle number?
---@field get_dst fun(self: self): vibes.Position
---@field get_speed fun(self: self): number
---@field durability number
---@field texture vibes.Texture
---@field center vibes.Position
---@field last_center vibes.Position
---@field fire_particle particles.Fire?
--
-- State Fields
---@field _enemy_collided_ids table<any, boolean>
---@field _pending_reached_target boolean
--
-- Private Fields
---@field _on_collide fun(self: vibes.Projectile, enemy: vibes.Enemy)
---@field _on_reached_target fun(self: vibes.Projectile)
local Projectile = class "vibes.Projectile"

--- Check if a segment intersects an axis-aligned bounding box using the slab method
---@param p0 vibes.Position
---@param p1 vibes.Position
---@param min_x number
---@param min_y number
---@param max_x number
---@param max_y number
---@return boolean
local function segment_intersects_aabb(p0, p1, min_x, min_y, max_x, max_y)
  local dx = p1.x - p0.x
  local dy = p1.y - p0.y

  local t_min = 0
  local t_max = 1

  if dx ~= 0 then
    local inv_dx = 1 / dx
    local t1 = (min_x - p0.x) * inv_dx
    local t2 = (max_x - p0.x) * inv_dx
    if t1 > t2 then
      t1, t2 = t2, t1
    end
    t_min = math.max(t_min, t1)
    t_max = math.min(t_max, t2)
    if t_min > t_max then
      return false
    end
  else
    if p0.x < min_x or p0.x > max_x then
      return false
    end
  end

  if dy ~= 0 then
    local inv_dy = 1 / dy
    local t1 = (min_y - p0.y) * inv_dy
    local t2 = (max_y - p0.y) * inv_dy
    if t1 > t2 then
      t1, t2 = t2, t1
    end
    t_min = math.max(t_min, t1)
    t_max = math.min(t_max, t2)
    if t_min > t_max then
      return false
    end
  else
    if p0.y < min_y or p0.y > max_y then
      return false
    end
  end

  return t_max >= t_min and t_max >= 0 and t_min <= 1
end

local function wrap_value(value)
  if type(value) == "function" then
    return value
  else
    return function() return value end
  end
end

---@param opts projectile.Opts
function Projectile:init(opts)
  opts.durability = opts.durability or 1

  validate(opts, {
    src = Position,
    dst = Either { "function", Position },
    speed = Either { "function", "number" },
    durability = "number",
    on_collide = "function",
    on_reached_target = "function?",
    texture = "userdata",
    fire = "boolean?",
  })

  self.src = opts.src:clone()
  self.get_dst = wrap_value(opts.dst)
  self.get_speed = wrap_value(opts.speed)
  self.durability = opts.durability
  self.texture = opts.texture --[[@as love.Image]]
  self.center = self.src:add(
    Position.new(self.texture:getWidth() / 2, self.texture:getHeight() / 2)
  )
  self.last_center = self.center:clone()

  self._on_collide = wrap_value(opts.on_collide)
  self._on_reached_target = opts.on_reached_target or function() end

  self._enemy_collided_ids = {}
  self._pending_reached_target = false

  self.fire_particle = opts.fire and FireParticle.new { position = self.center }
    or nil
  if self.fire_particle then
    self.fire_particle:init {
      position = self.center,
      intensity = 1,
    }
  end

  State.projectiles[self.id] = self
end

function Projectile:remove()
  State.projectiles[self.id] = nil
  return true
end

function Projectile:can_target_enemy(enemy)
  return not self._enemy_collided_ids[enemy.id]
end

---@param enemy vibes.Enemy
---@return boolean
function Projectile:collides_with(enemy)
  if not self:can_target_enemy(enemy) then
    return false
  end

  -- TODO: This is not super good because the hitboxes look goofy compared to the
  -- actual sprites themselves, so we need to do a slightly better job of hitbox detection
  -- and/or where the "center" of the projectile is vs the "center" of the enemy's position.

  -- AABB around enemy based on physical size
  -- local half_w = enemy.physical_width / 2 -- TODO: evaluate /2 vs not /2
  -- local half_h = enemy.physical_height / 2

  local half_w = enemy.physical_width
  local half_h = enemy.physical_height
  local min_x = enemy.center.x - half_w
  local max_x = enemy.center.x + half_w
  local min_y = enemy.center.y - half_h
  local max_y = enemy.center.y + half_h

  -- First, quick point-in-rect check at current center
  if
    self.center.x > min_x
    and self.center.x < max_x
    and self.center.y > min_y
    and self.center.y < max_y
  then
    return true
  end

  -- Continuous collision detection: check segment from last_center to center
  if
    segment_intersects_aabb(
      self.last_center,
      self.center,
      min_x,
      min_y,
      max_x,
      max_y
    )
  then
    return true
  end

  return false

  --return self.center:distance_squared(enemy.center) < HIT_THRESHOLD
end

---@param enemy vibes.Enemy
---@return boolean removed Whether the projectile was removed
function Projectile:collide(enemy)
  self._enemy_collided_ids[enemy.id] = true

  self:_on_collide(enemy)
  self.durability = self.durability - 1
  if self.durability <= 0 then
    return self:remove()
  end

  return false
end

--- Update projectile position
---@param dt number
function Projectile:update(dt)
  -- Track previous center for CCD
  self.last_center = self.center:clone()

  local dst = self:get_dst()
  local sub = dst:sub(
    self.src:add(
      Position.new(self.texture:getWidth() / 2, self.texture:getHeight())
    )
  )
  local dist_sq = sub:magnitude_squared()

  -- If within destination threshold, defer removal until after collisions
  if dist_sq < DST_THRESHOLD_SQUARED then
    self._pending_reached_target = true
  end

  local norm = sub:normalize()
  local speed = self:get_speed()
  local move_dist = speed * Config.grid.cell_size * dt
  local move_dist_sq = move_dist * move_dist

  local old_src = self.src:clone()

  if move_dist_sq > dist_sq then
    -- Clamp to not overshoot and mark for post-collision removal
    local remaining = math.sqrt(dist_sq)
    self.src.x = self.src.x + norm.x * remaining
    self.src.y = self.src.y + norm.y * remaining
    self._pending_reached_target = true
  else
    self.src.x = self.src.x + norm.x * move_dist
    self.src.y = self.src.y + norm.y * move_dist
  end

  -- Recompute angle and center after movement so collisions use fresh data
  local direction = self:get_dst():sub(self.src)
  local angle = math.atan2(direction.y, direction.x)
  self.angle = angle

  local w, h = self.texture:getWidth() * 4, self.texture:getHeight() * 4
  local offset_x = w
  local offset_y = h / 2
  local cos_a = math.cos(angle)
  local sin_a = math.sin(angle)
  local rotated_offset_x = offset_x * cos_a - offset_y * sin_a
  local rotated_offset_y = offset_x * sin_a + offset_y * cos_a
  self.center = self.src:add(Position.new(rotated_offset_x, rotated_offset_y))

  if self.fire_particle then
    self.fire_particle:set_position(self.center)
    self.fire_particle:update(dt)
  end

  -- if self.poi
end

--- Draw the projectile
function Projectile:draw()
  love.graphics.setColor(1, 1, 1)

  -- Calculate angle based on direction
  local direction = self:get_dst():sub(self.src)

  -- Adjust center based on angle so the projectile's center is always correct
  local angle = self.angle or math.atan2(direction.y, direction.x)
  self.angle = angle

  -- TODO: why does it need to scaled x4?
  local w, h = self.texture:getWidth() * 4, self.texture:getHeight() * 4
  local offset_x = w
  local offset_y = h / 2
  -- Rotate the offset by the angle to get the correct center
  local cos_a = math.cos(angle)
  local sin_a = math.sin(angle)
  local rotated_offset_x = offset_x * cos_a - offset_y * sin_a
  local rotated_offset_y = offset_x * sin_a + offset_y * cos_a

  self.center = self.src:add(Position.new(rotated_offset_x, rotated_offset_y))

  if self.fire_particle then
    self.fire_particle:draw()
  end

  love.graphics.draw(self.texture, self.src.x, self.src.y, self.angle, 4, 4)
end

return Projectile
