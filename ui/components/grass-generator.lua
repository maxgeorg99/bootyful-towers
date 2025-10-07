local Random = require "vibes.engine.random"
local TilesetOverdrawn = require "vibes.data.tileset-overdrawn"

local random = Random.new {
  name = "TileGenerator",
}

---@class ui.Tile.Opts
---@field level_index number
---
---@class ui.Tile
---@field new fun(opts: ui.Tile.Opts): ui.Tile
---@field offset_x number
---@field offset_y number
---@field level_index number
local Tile = class "ui.Tile"

---@param opts ui.Tile.Opts
function Tile:init(opts)
  self.offset_x = math.floor(random:random() * 1000000)
  self.offset_y = math.floor(random:random() * 1000000)
  self.level_index = opts.level_index
end

---@param offset_x number
---@param offset_y number
---@param r number
---@param c number
---@param period number
---@return number
local function get_noise_offset(offset_x, offset_y, r, c, period)
  return love.math.noise(r / period + offset_y, c / period + offset_x)
end

---@param r number
---@param c number
---@return vibes.Texture
function Tile:texture(r, c)
  local noise_offset = get_noise_offset(self.offset_x, self.offset_y, r, c, 30)

  return assert(
    TilesetOverdrawn.get_random_tile_from_level_tile(
      self.level_index,
      noise_offset
    ),
    "unable to load texture"
  )
end

---@param r number
---@param c number
---@return vibes.Cell
function Tile:cell(r, c)
  local texture = self:texture(r, c)
  local cell = Cell.new(r, c)
  cell.texture = texture
  return cell
end

return Tile
