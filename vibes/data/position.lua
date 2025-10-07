---@class vibes.Position : vibes.Class
---@field new fun(x: number, y: number): vibes.Position
---@field init fun(self: vibes.Position, x: number, y: number)
---@field x number
---@field y number
local Position = class "vibes.position"

---@param x number
---@param y number
function Position:init(x, y)
  assert(type(x) == "number", "Position.x must be a number")
  assert(type(y) == "number", "Position.y must be a number")

  self.x = x
  self.y = y
end

---@return vibes.Position
function Position.zero() return Position.new(0, 0) end

--- @param other vibes.Position
--- @return boolean
function Position:eq(other) return self.x == other.x and self.y == other.y end

--- @param other vibes.Position
---@return vibes.Position
function Position:sub(other)
  return Position.new(self.x - other.x, self.y - other.y)
end

--- @param other vibes.Position
---@return vibes.Position
function Position:add(other)
  return Position.new(self.x + other.x, self.y + other.y)
end

---@return vibes.Position
function Position:normalize()
  local length = self:magnitude()
  if length == 0 then
    return Position.new(0, 0)
  end
  return Position.new(self.x / length, self.y / length)
end

---@param other vibes.Position
function Position:set(other)
  self.x = other.x
  self.y = other.y
end

---@return number
function Position:magnitude()
  return math.sqrt(self.x * self.x + self.y * self.y)
end

---@return number
function Position:magnitude_squared() return self.x * self.x + self.y * self.y end

---@param other vibes.Position
---@return number
function Position:distance(other) return (self:sub(other)):magnitude() end

---@param other vibes.Position
---@return number
function Position:distance_squared(other)
  return (self:sub(other)):magnitude_squared()
end

---@param cell vibes.Cell | vibes.InlinedCell
---@return vibes.Position
function Position.from_cell(cell)
  local grid_size = Config.grid.cell_size
  return Position.new(
    cell.col * grid_size + grid_size / 2,
    cell.row * grid_size + grid_size / 2
  )
end

---@param cell vibes.Cell
---@return vibes.Position
function Position.from_cell_to_top_left(cell)
  local grid_size = Config.grid.cell_size
  return Position.new(cell.col * grid_size, cell.row * grid_size)
end

---@param scalar number
---@return vibes.Position
function Position:scale(scalar)
  return Position.new(self.x * scalar, self.y * scalar)
end
---@return vibes.Position
function Position:clone() return Position.new(self.x, self.y) end

function Position:__tostring()
  return string.format("Position(%s, %s)", self.x, self.y)
end

return Position
