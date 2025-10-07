local asset = require "vibes.asset"

local M = {}

M.draw_shadow = function(scale, x, y, additional_x_offset)
  local shadow = asset.sprites.shadow
  love.graphics.setColor(0, 0, 0, 0.5)
  love.graphics.draw(
    shadow,
    x + additional_x_offset,
    y,
    0,
    scale,
    scale,
    shadow:getWidth() / 2,
    shadow:getHeight() / 2
  )
  love.graphics.setColor(1, 1, 1, 1)
end

---@param texture vibes.Texture
---@param position vibes.Position
---@param scale number
---@param flipped boolean
M.shifted_draw = function(texture, position, scale, flipped)
  -- Draw tower texture from bottom-center
  local x_modifier = flipped and -1 or 1

  local frame_width = texture:getWidth()
  local frame_height = texture:getHeight()

  love.graphics.draw(
    texture,
    position.x,
    position.y,
    0, -- rotation
    scale * x_modifier, -- scale X
    scale, -- scale Y
    frame_width / 2, -- origin offset X (center)
    frame_height
  )
end

return M
