---@class vibes.NonPlaceableArea
---@field _type "vibes.non_placeable_area"
---@field cell vibes.Cell The grid cell that is non-placeable
local NonPlaceableArea = {}

--- Creates a new non-placeable area
---@param cell vibes.Cell
---@return vibes.NonPlaceableArea
function NonPlaceableArea.new(cell)
  assert(
    cell._type == "vibes.cell",
    "NonPlaceableArea.cell must be a vibes.Cell"
  )

  return {
    _type = "vibes.non_placeable_area",
    cell = cell,
  }
end

return NonPlaceableArea
