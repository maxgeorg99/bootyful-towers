local Object = require "vendor.object"

---@class vibes.NineSlice
---@field image love.Image
---@field top_left love.Quad
---@field top_center love.Quad
---@field top_right love.Quad
---@field middle_left love.Quad
---@field middle_center love.Quad
---@field middle_right love.Quad
---@field bottom_left love.Quad
---@field bottom_center love.Quad
---@field bottom_right love.Quad
---@field frame_width number
---@field frame_height number
local NineSlice = Object.new "utils.NineSlice"

-- Nine slice uses a 3x3 grid
local grid_size = 3

---@param image vibes.Texture
---@return vibes.NineSlice
function NineSlice.new(image)
  local frame_width = image:getWidth() / grid_size
  local frame_height = image:getHeight() / grid_size

  local frames = {}
  for row = 0, grid_size - 1 do
    for col = 0, grid_size - 1 do
      local index = row * grid_size + col + 1
      frames[index] = love.graphics.newQuad(
        col * frame_width,
        row * frame_height,
        frame_width,
        frame_height,
        image:getWidth(),
        image:getHeight()
      )
    end
  end

  return setmetatable({
    image = image,
    top_left = frames[1],
    top_center = frames[2],
    top_right = frames[3],
    middle_left = frames[4],
    middle_center = frames[5],
    middle_right = frames[6],
    bottom_left = frames[7],
    bottom_center = frames[8],
    bottom_right = frames[9],
    frame_width = frame_width,
    frame_height = frame_height,
  }, NineSlice)
end

return NineSlice
