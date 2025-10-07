-- blood.lua

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

---@class (exact) particles.Blood.Opts
---@field position? vibes.Position: initial position (defaults to origin)
---@field intensity? number: initial intensity (0-1, defaults to 1.0)

---@class (exact) particles.Blood : vibes.Class
---@field new fun(opts?: particles.Blood.Opts): particles.Blood
---@field init fun(self, opts?: particles.Blood.Opts)
---@field x number: x position of the blood
---@field y number: y position of the blood
---@field blood_system love.ParticleSystem: main blood particle system
---@field droplets_system love.ParticleSystem: droplets particle system
---@field base_blood_config table: base configuration for blood particles
---@field base_droplets_config table: base configuration for droplet particles
---@field intensity number: current blood intensity (0-1)
local BloodParticle = class "vibes.BloodParticle"

--- Creates a new blood particle system
---@param opts? particles.Blood.Opts
function BloodParticle:init(opts)
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

  -- Base blood configuration (short-lived splatter)
  self.base_blood_config = {
    emission = 0, -- use burst, not continuous
    lifetime = { 0.10, 0.22 },
    direction = -math.pi / 2,
    spread = math.rad(75),
    speed = { 60, 160 },
    linear_acceleration = { -20, -80, 20, -260 },
    radial_acceleration = { 0, 80 },
    sizes = { 0.22, 0.45, 0.75 },
    area = { "normal", 7, 3 },
  }

  -- Base droplets configuration (short-lived)
  self.base_droplets_config = {
    emission = 0, -- use burst
    lifetime = { 0.08, 0.18 },
    direction = -math.pi / 2,
    spread = math.rad(30),
    speed = { 90, 240 },
    linear_acceleration = { -40, -60, 40, -260 },
    sizes = { 0.12, 0.04 },
    area = { "normal", 6, 2 },
  }

  -- Initialize blood particle system
  self.blood_system = love.graphics.newParticleSystem(particle_image, 800)
  self:_setup_blood_system()

  -- Initialize droplets particle system
  self.droplets_system = love.graphics.newParticleSystem(particle_image, 400)
  self:_setup_droplets_system()

  -- Apply initial intensity
  self:set_intensity(self.intensity)
end

--- Sets up the blood particle system with base configuration
function BloodParticle:_setup_blood_system()
  local config = self.base_blood_config

  self.blood_system:setParticleLifetime(config.lifetime[1], config.lifetime[2])
  self.blood_system:setDirection(config.direction)
  self.blood_system:setSpread(config.spread)
  self.blood_system:setSpeed(config.speed[1], config.speed[2])
  self.blood_system:setLinearAcceleration(unpack(config.linear_acceleration))
  self.blood_system:setRadialAcceleration(unpack(config.radial_acceleration))
  self.blood_system:setSizes(unpack(config.sizes))
  self.blood_system:setSizeVariation(1)
  self.blood_system:setSpin(-2, 2)
  self.blood_system:setEmissionRate(0)
  self.blood_system:setColors(
    0.70,
    0.05,
    0.08,
    1.00, -- deep red
    0.45,
    0.02,
    0.06,
    0.70, -- darker red
    0.25,
    0.00,
    0.04,
    0.30 -- near black red
  )
  self.blood_system:start()
end

--- Sets up the droplets particle system with base configuration
function BloodParticle:_setup_droplets_system()
  local config = self.base_droplets_config

  self.droplets_system:setParticleLifetime(
    config.lifetime[1],
    config.lifetime[2]
  )
  self.droplets_system:setDirection(config.direction)
  self.droplets_system:setSpread(config.spread)
  self.droplets_system:setSpeed(config.speed[1], config.speed[2])
  self.droplets_system:setLinearAcceleration(unpack(config.linear_acceleration))
  self.droplets_system:setSizes(unpack(config.sizes))
  self.droplets_system:setSizeVariation(1)
  self.droplets_system:setEmissionRate(0)
  self.droplets_system:setColors(
    0.75,
    0.08,
    0.10,
    1.0, -- deep red
    0.50,
    0.04,
    0.08,
    0.55, -- darker red
    0.28,
    0.02,
    0.05,
    0.0 -- fade to near black
  )
  self.droplets_system:start()
end

--- Sets the blood intensity, affecting emission, size, speed, and spread
---@param new_intensity number: intensity value between 0 and 1
function BloodParticle:set_intensity(new_intensity)
  self.intensity = clamp(new_intensity, 0, 1)

  -- Keep systems burst-only; no continuous emission. Optionally scale size/speed.
  local t = self.intensity
  local blood_config = self.base_blood_config
  local droplets_config = self.base_droplets_config

  local size_factor = lerp(0.8, 1.2, t)
  self.blood_system:setSizes(
    unpack(scale_sizes(blood_config.sizes, size_factor))
  )
  self.droplets_system:setSizes(
    unpack(scale_sizes(droplets_config.sizes, size_factor * 0.9))
  )

  local blood_speed_min =
    lerp(blood_config.speed[1] * 0.9, blood_config.speed[1] * 1.2, t)
  local blood_speed_max =
    lerp(blood_config.speed[2] * 0.9, blood_config.speed[2] * 1.2, t)
  self.blood_system:setSpeed(blood_speed_min, blood_speed_max)

  local droplets_speed_min =
    lerp(droplets_config.speed[1] * 0.9, droplets_config.speed[1] * 1.2, t)
  local droplets_speed_max =
    lerp(droplets_config.speed[2] * 0.9, droplets_config.speed[2] * 1.2, t)
  self.droplets_system:setSpeed(droplets_speed_min, droplets_speed_max)

  self.blood_system:setSpread(
    lerp(blood_config.spread * 0.9, blood_config.spread * 1.1, t)
  )
  self.droplets_system:setSpread(
    lerp(droplets_config.spread * 0.9, droplets_config.spread * 1.05, t)
  )

  self.blood_system:setEmissionRate(0)
  self.droplets_system:setEmissionRate(0)
end

--- Gets the current blood intensity
---@return number: current intensity (0-1)
function BloodParticle:get_intensity() return self.intensity end

--- Sets the position of the blood particle system
---@param position vibes.Position: new position
function BloodParticle:set_position(position)
  if not position then
    return
  end

  self.x = position.x
  self.y = position.y
end

--- Updates the particle systems
---@param dt number: delta time
function BloodParticle:update(dt)
  self.blood_system:setPosition(self.x, self.y)
  self.droplets_system:setPosition(self.x, self.y - 6)
  self.blood_system:update(dt)
  self.droplets_system:update(dt)
end

--- Draws the blood particle systems with additive blending
function BloodParticle:draw()
  love.graphics.setBlendMode "add"
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(self.blood_system)
  love.graphics.draw(self.droplets_system)
  love.graphics.setBlendMode "alpha"
end

--- Emit a short-lived burst of blood and droplets
---@param strength number: 0..1 multiplier for particles
function BloodParticle:burst(strength)
  local s = clamp(F.if_nil(strength, 1.0), 0, 1)
  -- Position already maintained externally; just emit
  local main_particles = math.floor(28 + 36 * s)
  local droplet_particles = math.floor(10 + 18 * s)
  self.blood_system:emit(main_particles)
  self.droplets_system:emit(droplet_particles)
end

return BloodParticle
