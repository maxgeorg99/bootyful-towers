local time = require "vibes.engine.time"

---@class vibes.SpriteAnimationOptions
---@field image love.Image
---@field framerate number
---@field frame_count number
---@field frame_offset number?

---@class (exact) vibes.SpriteAnimation : vibes.Class
---@field new fun(opts: vibes.SpriteAnimationOptions): vibes.SpriteAnimation
---@field init fun(self, opts: vibes.SpriteAnimationOptions)
---@field image love.Image
---@field frame_count number
---@field framerate number
---@field frames love.Quad[]
---@field frame_width number
---@field frame_height number
---@field frame_offset number
local SpriteAnimation = class "vibes.SpriteAnimation"

--- Create a new SpriteAnimation using an options table
---@param opts vibes.SpriteAnimationOptions
---@return vibes.SpriteAnimation
function SpriteAnimation:init(opts)
  validate(opts, {
    image = "userdata",
    frame_count = "number",
    framerate = "number",
  })

  local frame_width = opts.image:getWidth() / opts.frame_count
  local frame_height = opts.image:getHeight()

  local frames = {}
  for i = 1, opts.frame_count do
    frames[i] = love.graphics.newQuad(
      (i - 1) * frame_width,
      0,
      frame_width,
      frame_height,
      opts.image:getWidth(),
      opts.image:getHeight()
    )
  end

  self.image = opts.image
  self.frame_count = opts.frame_count
  self.framerate = opts.framerate
  self.frames = frames
  self.frame_width = frame_width
  self.frame_height = frame_height
  self.frame_offset = opts.frame_offset or 0
end

---@param position vibes.Position
---@param scale number
---@param flipped boolean
function SpriteAnimation:draw(position, scale, flipped)
  local frame = self:texture()
  local x_modifier = flipped and -1 or 1

  -- Draw the sprite with bottom-center as the origin
  love.graphics.draw(
    self.image,
    frame,
    position.x,
    position.y,
    0,
    scale * x_modifier,
    scale,
    self.frame_width / 2,
    self.frame_height
  )

  if State.debug then
    love.graphics.setColor(0, 0, 0)
    love.graphics.circle("line", position.x, position.y, 3)
    love.graphics.setColor(1, 1, 1)
  end
  love.graphics.setColor(1, 1, 1)
end

function SpriteAnimation:texture()
  local current_frame = math.floor(
    time.gametime() * self.framerate + self.frame_offset
  ) % self.frame_count
  return self.frames[current_frame + 1]
end

return SpriteAnimation
