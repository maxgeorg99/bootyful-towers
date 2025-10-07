---@class vibes.GameAnimation
---@field position vibes.Position
---@field animation vibes.SpriteAnimation
---@field played boolean
---@field current_frame number
---@field frame_timer number
---@field frame_duration number
---@field scale number

---@class vibes.GameAnimationSystemOptions
---@field animations vibes.GameAnimation[]

---@class vibes.GameAnimationSystem : vibes.Class, vibes.System
---@field new fun(): vibes.GameAnimationSystem
---@field init fun(self: vibes.GameAnimationSystem)
---@field name string
---@field animations vibes.GameAnimation[]
---@field update fun(self: vibes.GameAnimationSystem, dt: number)
---@field draw fun(self: vibes.GameAnimationSystem)
local GameAnimationSystem = class "vibes.GameAnimationSystem"

function GameAnimationSystem:init()
  self.name = "GameAnimationSystem"
  self.animations = {}
end

function GameAnimationSystem:update(dt)
  local i = 1
  while i <= #self.animations do
    local animation = self.animations[i]
    animation.frame_timer = animation.frame_timer + dt
    if animation.frame_timer >= animation.frame_duration then
      animation.frame_timer = animation.frame_timer - animation.frame_duration
      animation.current_frame = animation.current_frame + 1

      if animation.current_frame > #animation.animation.frames then
        animation.played = true
        table.remove(self.animations, i)
      else
        i = i + 1
      end
    else
      i = i + 1
    end
  end
end

function GameAnimationSystem:draw()
  for _, animation in ipairs(self.animations) do
    animation.animation:draw(animation.position, animation.scale or 1, false)
  end
end

function GameAnimationSystem:_play_animation(opts)
  validate(opts, {
    position = Position,
    animation = "table",
    frame_duration = "number",
  })

  table.insert(self.animations, {
    position = opts.position,
    animation = opts.animation,
    played = false,
    current_frame = 1,
    frame_timer = 0,
    frame_duration = opts.frame_duration,
    scale = opts.scale or 1,
  })
end

--- Play a death coin animation at the specified position
---@param position vibes.Position
function GameAnimationSystem:play_death_coin(position)
  self:_play_animation {
    position = position,
    animation = Asset.animations.death_coin,
    frame_duration = 0.1,
  }
end

--- Play an explosion animation at the specified position
---@param position vibes.Position
function GameAnimationSystem:play_explosion(position)
  self:_play_animation {
    position = position,
    animation = Asset.animations.explosion,
    frame_duration = 0.05,
  }
end

--- Play multiple explosion animations within an AOE range
--- The number of explosions scales with the range for a more impactful effect
---@param position vibes.Position: The center position of the AOE
---@param aoe_range number: The radius of the AOE in grid cells
function GameAnimationSystem:play_aoe_explosions(position, aoe_range)
  -- Calculate number of explosions based on AOE range
  -- More range = more explosions for a more impactful visual
  local explosion_count = math.max(3, math.floor(aoe_range * 3))

  -- Convert AOE range from grid cells to pixel distance
  local pixel_range = aoe_range * Config.grid.cell_size

  -- Scale center explosion to fit the AOE range
  -- The base explosion sprite is roughly 1 cell size, so scale to match AOE
  local center_scale = aoe_range * 0.5

  -- Scattered explosions are smaller
  local scattered_scale = 0.35

  -- Always play one explosion at the center that fills the AOE
  self:_play_animation {
    position = position,
    animation = Asset.animations.explosion,
    frame_duration = 0.05,
    scale = center_scale,
  }

  -- Play additional explosions scattered within the AOE
  for i = 1, explosion_count - 1 do
    -- Generate a random position within the circular AOE
    local angle = love.math.random() * math.pi * 2
    local distance = love.math.random() * pixel_range

    local offset_x = math.cos(angle) * distance
    local offset_y = math.sin(angle) * distance

    local explosion_pos = position:add(Position.new(offset_x, offset_y))

    -- Slight variation in frame duration for a more dynamic effect
    local frame_variation = (love.math.random() - 0.5) * 0.02
    self:_play_animation {
      position = explosion_pos,
      animation = Asset.animations.explosion,
      frame_duration = 0.05 + frame_variation,
      scale = scattered_scale,
    }
  end
end

---@param position vibes.Position
function GameAnimationSystem:play_fire(position)
  local variation_x = 0
  local variation_y = 0

  local pos = position:sub(Position.new(variation_x, variation_y))
  self:_play_animation {
    position = pos,
    animation = Asset.animations.fire_1,
    frame_duration = 0.1,
  }

  self:_play_animation {
    position = pos,
    animation = Asset.animations.fire_2,
    frame_duration = 0.1,
  }

  self:_play_animation {
    position = pos,
    animation = Asset.animations.fire_3,
    frame_duration = 0.1,
  }
end

function GameAnimationSystem:play_poison_pool(position, duration)
  self:_play_animation {
    position = position,
    animation = Asset.animations.poison_1,
    frame_duration = duration,
  }

  self:_play_animation {
    position = position,
    animation = Asset.animations.poison_2,
    frame_duration = duration,
  }

  self:_play_animation {
    position = position,
    animation = Asset.animations.poison_3,
    frame_duration = duration,
  }
end

return GameAnimationSystem.new()
