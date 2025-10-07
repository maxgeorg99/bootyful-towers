local TilesetOverdrawn = require "vibes.data.tileset-overdrawn"
local OVERDRAW_SIZE = TilesetOverdrawn.OVERDRAWN_SIZE
local TEXTURE_SIZE = TilesetOverdrawn.TEXTURE_SIZE

---@class (exact) components.TileOverdrawn.Opts
---@field cell vibes.Cell
---@field position vibes.Position
---
---@class (exact) components.TileOverdrawn: Element
---@field cell vibes.Cell
---@field new fun(opts: components.TileOverdrawn.Opts): components.TileOverdrawn
local TileOverdrawn = class("components.TileOverdrawn", { super = Element })

function TileOverdrawn:init(opts)
  validate(opts, {
    cell = Cell,
    position = Position,
  })

  self.cell = opts.cell
  local box =
    Box.new(opts.position, Config.grid.cell_size, Config.grid.cell_size)
  Element.init(self, box, opts)
end

function TileOverdrawn:_render()
  local overdrawn_mount = OVERDRAW_SIZE - TEXTURE_SIZE
  local x, y = self:get_geo()

  x = x - overdrawn_mount
  y = y - overdrawn_mount

  love.graphics.draw(self.cell.texture, x, y, 0, 2, 2)
end

return TileOverdrawn
