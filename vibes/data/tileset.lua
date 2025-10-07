local M = {}

---@alias vibes.Tileset vibes.Texture[][]

---@param sprite_name string name of the sprite located at assets/sprites/<sprite_name.png>
---@param grid_size number | nil the size of the sprite length (expecting a square sprite) default = Config.grid.native_cell_size
---@return vibes.Tileset
M.load_spritesheet = function(sprite_name, grid_size)
  grid_size = grid_size or Config.grid.native_cell_size

  local source_image = love.image.newImageData("assets/sprites/" .. sprite_name)

  local width = source_image:getWidth()
  local height = source_image:getHeight()
  local col = 0
  local row = 0
  local tileset = {}

  while row < height do
    local tileset_row = {}
    table.insert(tileset, tileset_row)

    col = 0
    while col < width do
      local sprite_image = love.image.newImageData(grid_size, grid_size)
      sprite_image:paste(source_image, 0, 0, col, row, grid_size, grid_size)

      table.insert(tileset_row, love.graphics.newImage(sprite_image))

      col = col + grid_size
    end

    row = row + grid_size
  end

  return tileset
end

return M
