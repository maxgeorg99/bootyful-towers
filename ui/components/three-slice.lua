---@class components.ThreeSlice : Element
---@field new fun(opts: components.ThreeSlice.Opts): components.ThreeSlice
---@field init fun(self: components.ThreeSlice, opts: components.ThreeSlice.Opts)
---@field image vibes.Texture
---@field left love.Quad
---@field center love.Quad
---@field right love.Quad
---@field frame_width number
---@field frame_height number
local ThreeSlice = class("slice.Three", { super = Element })

-- Duh its a three slice
local frame_count = 3

---@class components.ThreeSlice.Opts
---@field box ui.components.Box
---@field image vibes.Texture

---@param opts components.ThreeSlice.Opts
function ThreeSlice:init(opts)
  validate(opts, {
    box = Box,
    image = "userdata",
  })

  Element.init(self, opts.box)

  self.frame_width = opts.image:getWidth() / frame_count
  self.frame_height = opts.image:getHeight()

  local frames = {}
  for i = 1, frame_count do
    frames[i] = love.graphics.newQuad(
      (i - 1) * self.frame_width,
      0,
      self.frame_width,
      self.frame_height,
      opts.image:getWidth(),
      opts.image:getHeight()
    )
  end

  self.image = opts.image
  self.left = frames[1]
  self.center = frames[2]
  self.right = frames[3]
end

function ThreeSlice:_render()
  -- Reset color for the frame
  love.graphics.setColor(1, 1, 1, 1)

  local x, y, w, h = self:get_geo()

  local scale_y = h / self.frame_height

  -- Draw left edge
  love.graphics.draw(self.image, self.left, x, y, 0, 1, scale_y)

  -- TODO: Could repeat this a few times, but for now it really doesn't make sense to
  --  We don't have any repeated textures that we need to fill in.
  local inner_scale_x = (w - self.frame_width * 2) / self.frame_width
  love.graphics.draw(
    self.image,
    self.center,
    x + self.frame_width,
    y,
    0,
    inner_scale_x,
    scale_y
  )

  -- Draw right edge
  local right_edge_x = x + w - self.frame_width
  love.graphics.draw(self.image, self.right, right_edge_x, y, 0, 1, scale_y)
end

return ThreeSlice
