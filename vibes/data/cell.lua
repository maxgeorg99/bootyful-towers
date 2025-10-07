local Random = require "vibes.engine.random"
local random = Random.new { name = "cell" }

---@class vibes.InlinedCell
---@field row number
---@field col number
---
---@class vibes.Cell : vibes.Class
---@field new fun(row: number, col: number): vibes.Cell
---@field init fun(self: vibes.Cell, row: number, col: number)
---@field row number
---@field col number
---@field texture vibes.Texture
---@field is_placeable boolean
---@field is_path boolean Whether this cell is part of an enemy path
---@field height number
---@field flip_texture boolean
local Cell = class "vibes.Cell"

--- Creates a new Cell
---@param row number
---@param col number
function Cell:init(row, col)
  assert(type(row) == "number", "Cell.row must be a number")
  assert(type(col) == "number", "Cell.col must be a number")

  self.row = row
  self.col = col
  self.is_placeable = true
  self.is_path = false
  -- self.height = random:random() > 0.5 and
  -- random:random() * 3 or random:random() * -4
  self.height = random:random() * 5 * 2
  self.flip_texture = random:random() > 0.5
end

---@param pos vibes.Position
---@return number, number
function Cell.to_cell_coordinates(pos)
  assert(type(pos) == "table", "Cell.to_cell_coordinates: table ")

  local g_row = math.floor(pos.y / Config.grid.cell_size)
  local g_col = math.floor(pos.x / Config.grid.cell_size)
  return g_row, g_col
end

---@param pos vibes.Position
---@return vibes.Cell
function Cell.from_position(pos)
  local g_row, g_col = Cell.to_cell_coordinates(pos)
  return Cell.new(g_row, g_col)
end

---@param other vibes.Cell
---@return number
function Cell:city_block_distance(other)
  return math.abs(self.row - other.row) + math.abs(self.col - other.col)
end

---@return vibes.Position
function Cell:center()
  return Position.new(
    self.col * Config.grid.cell_size + Config.grid.cell_size / 2,
    self.row * Config.grid.cell_size + Config.grid.cell_size / 2
  )
end

---@return ui.components.Box
function Cell:box()
  return Box.from(
    self.col * Config.grid.cell_size,
    self.row * Config.grid.cell_size,
    Config.grid.cell_size,
    Config.grid.cell_size
  )
end

function Cell:update()
  -- self.temporary_enemy_modifiers = {}
  -- self.enemy_modifiers = {}
end

function Cell:__tostring()
  return string.format("Cell(%d, %d)", self.row, self.col)
end

return Cell
