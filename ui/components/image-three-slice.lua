---@class components.ImageThreeSlice : Element
---@field new fun(opts: components.ImageThreeSlice.Opts): components.ImageThreeSlice
---@field init fun(self: components.ImageThreeSlice, opts: components.ImageThreeSlice.Opts)
---@field left_image vibes.Texture
---@field center_image vibes.Texture
---@field right_image vibes.Texture
---@field scale number
---@field center_quad love.Quad
---@field last_middle_width number
local ImageThreeSlice = class("slice.ImageThree", { super = Element })

---@class components.ImageThreeSlice.Opts
---@field box ui.components.Box
---@field left_image vibes.Texture
---@field center_image vibes.Texture
---@field right_image vibes.Texture

---@param opts components.ImageThreeSlice.Opts
function ImageThreeSlice:init(opts)
  validate(opts, {
    box = Box,
    left_image = "userdata",
    center_image = "userdata",
    right_image = "userdata",
  })

  Element.init(self, opts.box)

  self.scale = opts.box.height / opts.left_image:getHeight()
  self.left_image = opts.left_image
  self.center_image = opts.center_image
  self.right_image = opts.right_image

  self.center_image:setWrap("repeat", "clamp")

  self.center_quad = nil
  self.last_middle_width = -1
end

function ImageThreeSlice:_render()
  -- Reset color for the frame
  love.graphics.setColor(1, 1, 1, 1)

  local x, y, w, h = self:get_geo()

  -- Calculate proportional scaling for end pieces
  -- The end pieces maintain their aspect ratio with the scale factor
  local left_width = self.left_image:getWidth() * self.scale
  local right_width = self.right_image:getWidth() * self.scale

  -- Draw left edge with proportional scaling
  love.graphics.draw(self.left_image, x, y, 0, self.scale, self.scale)

  -- Calculate the remaining space for the middle section
  local middle_width = w - left_width - right_width
  local middle_x = x + left_width

  if middle_width > 0 then
    local scale_y_center = h / self.center_image:getHeight()

    -- Only create/update the quad if the middle width has changed
    if self.last_middle_width ~= middle_width then
      self.center_quad = love.graphics.newQuad(
        0,
        0,
        middle_width / self.scale, -- Adjust for scale
        self.center_image:getHeight(),
        self.center_image:getWidth(),
        self.center_image:getHeight()
      )
      self.last_middle_width = middle_width
    end

    -- Draw the center section with horizontal wrapping
    love.graphics.draw(
      self.center_image,
      self.center_quad,
      middle_x,
      y,
      0,
      self.scale,
      scale_y_center
    )
  end

  -- Draw right edge with proportional scaling
  local right_edge_x = x + w - right_width
  love.graphics.draw(
    self.right_image,
    right_edge_x,
    y,
    0,
    self.scale,
    self.scale
  )
end

return ImageThreeSlice
