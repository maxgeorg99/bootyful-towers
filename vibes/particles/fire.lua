-- fire.lua

--- Creates a circular particle image
---@param radius number: radius of the circle
---@return love.Image
local function make_circle_image(radius)
  local diameter = radius * 2
  local image_data = love.image.newImageData(diameter, diameter)
  image_data:mapPixel(function(x, y)
    local dx, dy = (x - radius + 0.5), (y - radius + 0.5)
    local distance = math.sqrt(dx * dx + dy * dy)
    local alpha = (distance <= radius) and (1 - (distance / radius) ^ 2) or 0
    return 255, 255, 255, math.floor(alpha * 255 + 0.5)
  end)
  return love.graphics.newImage(image_data)
end

--- Clamps a value between min and max
---@param value number: value to clamp
---@param min number: minimum value
---@param max number: maximum value
---@return number
local function clamp(value, min, max) return math.max(min, math.min(max, value)) end

--- Linear interpolation between two values
---@param a number: start value
---@param b number: end value
---@param t number: interpolation factor (0-1)
---@return number
local function lerp(a, b, t) return a + (b - a) * t end

--- Scales all sizes in a table by a factor
---@param sizes number[]: array of sizes to scale
---@param factor number: scaling factor
---@return number[]
local function scale_sizes(sizes, factor)
  local scaled = {}
  for i, size in ipairs(sizes) do
    scaled[i] = size * factor
  end
  return scaled
end

---@class (exact) particles.Fire.Opts
---@field position? vibes.Position: initial position (defaults to origin)
---@field intensity? number: initial intensity (0-1, defaults to 1.0)

---@class (exact) particles.Fire : vibes.Class
---@field new fun(opts?: particles.Fire.Opts): particles.Fire
---@field init fun(self, opts?: particles.Fire.Opts)
---@field x number: x position of the fire
---@field y number: y position of the fire
---@field fire_system love.ParticleSystem: main fire particle system
---@field sparks_system love.ParticleSystem: sparks particle system
---@field base_fire_config table: base configuration for fire particles
---@field base_sparks_config table: base configuration for spark particles
---@field intensity number: current fire intensity (0-1)
local FireParticle = class "vibes.FireParticle"

--- Creates a new fire particle system
---@param opts? particles.Fire.Opts
function FireParticle:init(opts)
  opts = opts or {}

  -- Set defaults
  opts.position = opts.position or Position.new(0, 0)
  opts.intensity = F.if_nil(opts.intensity, 1.0)

  validate(opts, {
    position = Position,
    intensity = "number",
  })

  self.x = opts.position.x
  self.y = opts.position.y
  self.intensity = opts.intensity

  -- Create particle image
  local particle_image = make_circle_image(8)

  -- Base fire configuration
  self.base_fire_config = {
    emission = 160,
    lifetime = { 0.35, 0.75 },
    direction = -math.pi / 2,
    spread = math.rad(80),
    speed = { 35, 110 },
    linear_acceleration = { -10, -60, 10, -180 },
    radial_acceleration = { 0, 60 },
    sizes = { 0.25, 0.55, 0.9 },
    area = { "normal", 7, 3 },
  }

  -- Base sparks configuration
  self.base_sparks_config = {
    emission = 60,
    lifetime = { 0.4, 1.0 },
    direction = -math.pi / 2,
    spread = math.rad(25),
    speed = { 80, 200 },
    linear_acceleration = { -30, -40, 30, -220 },
    sizes = { 0.15, 0.05 },
    area = { "normal", 6, 2 },
  }

  -- Initialize fire particle system
  self.fire_system = love.graphics.newParticleSystem(particle_image, 800)
  self:_setup_fire_system()

  -- Initialize sparks particle system
  self.sparks_system = love.graphics.newParticleSystem(particle_image, 400)
  self:_setup_sparks_system()

  -- Apply initial intensity
  self:set_intensity(self.intensity)
end

--- Sets up the fire particle system with base configuration
function FireParticle:_setup_fire_system()
  local config = self.base_fire_config

  self.fire_system:setParticleLifetime(config.lifetime[1], config.lifetime[2])
  self.fire_system:setDirection(config.direction)
  self.fire_system:setSpread(config.spread)
  self.fire_system:setSpeed(config.speed[1], config.speed[2])
  self.fire_system:setLinearAcceleration(unpack(config.linear_acceleration))
  self.fire_system:setRadialAcceleration(unpack(config.radial_acceleration))
  self.fire_system:setSizes(unpack(config.sizes))
  self.fire_system:setSizeVariation(1)
  self.fire_system:setSpin(-2, 2)
  self.fire_system:setEmissionRate(config.emission)
  self.fire_system:setColors(
    1.00,
    0.92,
    0.50,
    1.00, -- bright yellow-orange
    1.00,
    0.55,
    0.20,
    0.85, -- orange-red
    0.85,
    0.25,
    0.06,
    0.45 -- deep red
  )
  self.fire_system:start()
end

--- Sets up the sparks particle system with base configuration
function FireParticle:_setup_sparks_system()
  local config = self.base_sparks_config

  self.sparks_system:setParticleLifetime(config.lifetime[1], config.lifetime[2])
  self.sparks_system:setDirection(config.direction)
  self.sparks_system:setSpread(config.spread)
  self.sparks_system:setSpeed(config.speed[1], config.speed[2])
  self.sparks_system:setLinearAcceleration(unpack(config.linear_acceleration))
  self.sparks_system:setSizes(unpack(config.sizes))
  self.sparks_system:setSizeVariation(1)
  self.sparks_system:setColors(
    1.00,
    0.9,
    0.6,
    1.0, -- bright yellow-white
    1.00,
    0.6,
    0.2,
    0.6, -- orange
    1.00,
    1.0,
    1.0,
    0.0 -- fade to white
  )
  self.sparks_system:start()
end

--- Sets the fire intensity, affecting emission, size, speed, and spread
---@param new_intensity number: intensity value between 0 and 1
function FireParticle:set_intensity(new_intensity)
  self.intensity = clamp(new_intensity, 0, 1)

  local t = self.intensity
  local fire_config = self.base_fire_config
  local sparks_config = self.base_sparks_config

  -- Emission: 0..1 of base
  self.fire_system:setEmissionRate(fire_config.emission * t)
  self.sparks_system:setEmissionRate(sparks_config.emission * t)

  -- Size: shrink to 40% at 0, up to 160% at 1
  local size_factor = lerp(0.4, 1.6, t)
  self.fire_system:setSizes(unpack(scale_sizes(fire_config.sizes, size_factor)))
  self.sparks_system:setSizes(
    unpack(scale_sizes(sparks_config.sizes, size_factor * 0.75))
  )

  -- Speed: 70%..180% of base
  local fire_speed_min =
    lerp(fire_config.speed[1] * 0.7, fire_config.speed[1] * 1.8, t)
  local fire_speed_max =
    lerp(fire_config.speed[2] * 0.7, fire_config.speed[2] * 1.8, t)
  self.fire_system:setSpeed(fire_speed_min, fire_speed_max)

  local sparks_speed_min =
    lerp(sparks_config.speed[1] * 0.7, sparks_config.speed[1] * 1.8, t)
  local sparks_speed_max =
    lerp(sparks_config.speed[2] * 0.7, sparks_config.speed[2] * 1.8, t)
  self.sparks_system:setSpeed(sparks_speed_min, sparks_speed_max)

  -- Spread: slightly wider with heat
  self.fire_system:setSpread(
    lerp(fire_config.spread * 0.8, fire_config.spread * 1.15, t)
  )
  self.sparks_system:setSpread(
    lerp(sparks_config.spread * 0.8, sparks_config.spread * 1.05, t)
  )

  -- Area jitter grows to feel "larger" flame
  local fire_area_x =
    lerp(fire_config.area[2] * 0.6, fire_config.area[2] * 1.5, t)
  local fire_area_y =
    lerp(fire_config.area[3] * 0.6, fire_config.area[3] * 1.2, t)
  self.fire_system:setEmissionArea(
    fire_config.area[1],
    fire_area_x,
    fire_area_y
  )

  local sparks_area_x =
    lerp(sparks_config.area[2] * 0.6, sparks_config.area[2] * 1.3, t)
  local sparks_area_y =
    lerp(sparks_config.area[3] * 0.6, sparks_config.area[3] * 1.1, t)
  self.sparks_system:setEmissionArea(
    sparks_config.area[1],
    sparks_area_x,
    sparks_area_y
  )
end

--- Gets the current fire intensity
---@return number: current intensity (0-1)
function FireParticle:get_intensity() return self.intensity end

--- Sets the position of the fire particle system
---@param position vibes.Position: new position
function FireParticle:set_position(position)
  if not position then
    return
  end

  self.x = position.x
  self.y = position.y
end

--- Updates the particle systems
---@param dt number: delta time
function FireParticle:update(dt)
  self.fire_system:setPosition(self.x, self.y)
  self.sparks_system:setPosition(self.x, self.y - 6)
  self.fire_system:update(dt)
  self.sparks_system:update(dt)
end

--- Draws the fire particle systems with additive blending
function FireParticle:draw()
  love.graphics.setBlendMode "add"
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(self.fire_system)
  love.graphics.draw(self.sparks_system)
  love.graphics.setBlendMode "alpha"
end

return FireParticle
