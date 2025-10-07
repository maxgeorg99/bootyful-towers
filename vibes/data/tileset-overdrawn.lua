local Random = require "vibes.engine.random"
local M = {}

local OVERDRAW_SIZE = 48
local TEXTURE_SIZE = 36
local random = Random.new {
  name = "overdrawn_tileset",
}

---@class vibes.OverdrawnTileset
---@field paths vibes.Texture[]
---@field grass vibes.Texture[]

---@param level_index number
---@param noise_offset number
---@param tile_count number
---@param section_size number
---@return number
local function get_section_from_noise(
  level_index,
  noise_offset,
  tile_count,
  section_size
)
  level_index = math.max(1, math.min(level_index, 10))
  local min_start = 1
  local max_start = tile_count - section_size + 1

  local t = (level_index - 1) / 9
  local start_idx = math.floor(min_start + (max_start - min_start) * t + 0.5)
  start_idx = math.max(min_start, math.min(start_idx, max_start))

  local random_offset = random:random(-2, 2)

  local final_idx = start_idx
    + math.floor(section_size * noise_offset)
    + random_offset

  -- Ensure the index is within valid bounds
  final_idx = math.max(1, math.min(final_idx, tile_count))

  return final_idx
end

---@param level_index number
---@param noise_offset number
---@return vibes.Texture?
M.get_random_tile_from_level_tile = function(level_index, noise_offset)
  local idx = get_section_from_noise(
    level_index,
    noise_offset,
    Config.ui.tile_overdrawn.grass_length,
    10
  )
  return Asset.tilesets.overdrawn_sprites.grass[idx]
end

M.get_random_tile_for_path = function()
  local idx = random:random(1, Config.ui.tile_overdrawn.path_length)
  return Asset.tilesets.overdrawn_sprites.paths[idx]
end

---@param sprite_name string name of the sprite located at assets/sprites/<sprite_name.png>
---@return vibes.OverdrawnTileset
M.load_overdrawn_spritesheet = function(sprite_name)
  local source_image =
    love.image.newImageData("assets/sprites/tiles/" .. sprite_name)
  local width = source_image:getWidth()

  local tiles = width / OVERDRAW_SIZE

  local tileset = {
    paths = {},
    grass = {},
  }

  for row, key in ipairs { "paths", "grass" } do
    for i = 1, tiles do
      local sprite_image = love.image.newImageData(OVERDRAW_SIZE, OVERDRAW_SIZE)
      sprite_image:paste(
        source_image,
        0,
        0,
        (i - 1) * OVERDRAW_SIZE,
        (row - 1) * OVERDRAW_SIZE,
        OVERDRAW_SIZE,
        OVERDRAW_SIZE
      )

      table.insert(tileset[key], love.graphics.newImage(sprite_image))
    end
  end

  return tileset
end

---@param cell vibes.Cell
M.draw = function(cell)
  if not cell.texture then
    return
  end

  local x_offset = cell.col * Config.grid.cell_size
    - (OVERDRAW_SIZE - TEXTURE_SIZE)
  if cell.flip_texture then
    x_offset = x_offset + OVERDRAW_SIZE * 2
  end

  -- Use grass noise shader for grass tiles (non-path tiles)
  local use_grass_shader = not cell.is_path
  if use_grass_shader then
    local Time = require "vibes.engine.time"
    Asset.shaders.grass_noise:update_time(Time.now())
    love.graphics.setShader(Asset.shaders.grass_noise.shader)
  end

  local height = cell.height
  if cell.is_path then
    height = 0
  end

  cell.texture:setFilter("nearest", "nearest")

  love.graphics.draw(
    cell.texture,
    x_offset,
    cell.row * Config.grid.cell_size - (OVERDRAW_SIZE - TEXTURE_SIZE) - height,
    0,
    cell.flip_texture and -2 or 2,
    2
  )

  -- Reset shader after drawing grass
  if use_grass_shader then
    love.graphics.setShader()
  end
end

M.OVERDRAWN_SIZE = OVERDRAW_SIZE
M.TEXTURE_SIZE = TEXTURE_SIZE

return M
