--- Path analyzer module
--- Analyzes paths and determines appropriate tile types for each segment

local PathAnalyzer = {}

-- Directions constants
local NORTH = "north"
local SOUTH = "south"
local EAST = "east"
local WEST = "west"

-- Tile types
local TILE_TYPES = {
  HORIZONTAL = "horizontal", -- straight horizontal road (left to right)
  VERTICAL = "vertical", -- straight vertical road (top to bottom)
  CROSS = "cross", -- crossing
  CORNER_NE = "corner_ne", -- top-right corner
  CORNER_NW = "corner_nw", -- top-left corner
  CORNER_SE = "corner_se", -- bottom-right corner
  CORNER_SW = "corner_sw", -- bottom-left corner
  T_NORTH = "t_north", -- T-junction facing north
  T_SOUTH = "t_south", -- T-junction facing south
  T_EAST = "t_east", -- T-junction facing east
  T_WEST = "t_west", -- T-junction facing west
  END_NORTH = "end_north", -- dead end facing north
  END_SOUTH = "end_south", -- dead end facing south
  END_EAST = "end_east", -- dead end facing east
  END_WEST = "end_west", -- dead end facing west
}

-- Maps tile types to quad names from our GrassTiles system
-- For the 9-slice tileset we're using:
-- +---+---+---+
-- | 0 | 1 | 2 |
-- +---+---+---+
-- | 3 | 4 | 5 |
-- +---+---+---+
-- | 6 | 7 | 8 |
-- +---+---+---+
local TILE_TO_QUAD = {
  -- Straights
  [TILE_TYPES.HORIZONTAL] = "center", -- Center for horizontal paths
  [TILE_TYPES.VERTICAL] = "center", -- Center for vertical paths

  -- Corners
  [TILE_TYPES.CORNER_NE] = "top_right", -- Top-right cell for NE corners
  [TILE_TYPES.CORNER_NW] = "top_left", -- Top-left cell for NW corners
  [TILE_TYPES.CORNER_SE] = "bottom_right", -- Bottom-right cell for SE corners
  [TILE_TYPES.CORNER_SW] = "bottom_left", -- Bottom-left cell for SW corners

  -- T-junctions
  [TILE_TYPES.T_NORTH] = "top", -- Top cell for T-junctions facing north
  [TILE_TYPES.T_SOUTH] = "bottom", -- Bottom cell for T-junctions facing south
  [TILE_TYPES.T_EAST] = "right", -- Right cell for T-junctions facing east
  [TILE_TYPES.T_WEST] = "left", -- Left cell for T-junctions facing west

  -- Dead ends
  [TILE_TYPES.END_NORTH] = "top", -- Top cell for dead ends facing north
  [TILE_TYPES.END_SOUTH] = "bottom", -- Bottom cell for dead ends facing south
  [TILE_TYPES.END_EAST] = "right", -- Right cell for dead ends facing east
  [TILE_TYPES.END_WEST] = "left", -- Left cell for dead ends facing west

  -- Crossroads
  [TILE_TYPES.CROSS] = "center", -- Center cell for crossroads
}

-- Get the relative direction between two cells
---@param from vibes.Cell
---@param to vibes.Cell
---@return string direction
local function get_direction(from, to)
  if from.row > to.row then
    return NORTH
  elseif from.row < to.row then
    return SOUTH
  elseif from.col < to.col then
    return EAST
  elseif from.col > to.col then
    return WEST
  else
    return NORTH -- Default if same cell (shouldn't happen)
  end
end

-- Determine if two cells are adjacent
---@param a vibes.Cell
---@param b vibes.Cell
---@return boolean
local function are_adjacent(a, b)
  local row_diff = math.abs(a.row - b.row)
  local col_diff = math.abs(a.col - b.col)

  -- Cells are adjacent if they share a side (not a corner)
  return (row_diff == 1 and col_diff == 0) or (row_diff == 0 and col_diff == 1)
end

-- Get all cells adjacent to the given one within a grid
---@param cell vibes.Cell The cell to check adjacency for
---@param all_path_cells vibes.Cell[] All cells in the path
---@return table<string, vibes.Cell> A table with direction keys and cell values
local function get_adjacent_path_cells(cell, all_path_cells)
  local adjacent = {}

  for _, path_cell in ipairs(all_path_cells) do
    if are_adjacent(cell, path_cell) then
      local direction = get_direction(cell, path_cell)
      adjacent[direction] = path_cell
    end
  end

  return adjacent
end

-- Determine the type of tile needed for a cell based on its neighbors
---@param cell vibes.Cell The current cell
---@param cells vibes.Cell[] All cells in the path
---@return string tile_type The type of tile needed
local function determine_tile_type(cell, cells)
  local adjacent = get_adjacent_path_cells(cell, cells)
  local direction_count = 0

  -- Count adjacent cells
  for _ in pairs(adjacent) do
    direction_count = direction_count + 1
  end

  -- Determine tile type based on number and direction of neighbors
  if direction_count == 0 then
    -- Isolated cell (shouldn't normally happen in a path)
    return TILE_TYPES.CROSS
  elseif direction_count == 1 then
    -- End of path - determine which way it's facing
    if adjacent[NORTH] then
      return TILE_TYPES.END_SOUTH
    elseif adjacent[SOUTH] then
      return TILE_TYPES.END_NORTH
    elseif adjacent[EAST] then
      return TILE_TYPES.END_WEST
    else
      return TILE_TYPES.END_EAST
    end
  elseif direction_count == 2 then
    -- Either a straight section or a corner
    if adjacent[NORTH] and adjacent[SOUTH] then
      return TILE_TYPES.VERTICAL
    elseif adjacent[EAST] and adjacent[WEST] then
      return TILE_TYPES.HORIZONTAL
    elseif adjacent[NORTH] and adjacent[EAST] then
      return TILE_TYPES.CORNER_SW
    elseif adjacent[NORTH] and adjacent[WEST] then
      return TILE_TYPES.CORNER_SE
    elseif adjacent[SOUTH] and adjacent[EAST] then
      return TILE_TYPES.CORNER_NW
    else
      return TILE_TYPES.CORNER_NE
    end
  elseif direction_count == 3 then
    -- T-junction
    if not adjacent[NORTH] then
      return TILE_TYPES.T_SOUTH
    elseif not adjacent[SOUTH] then
      return TILE_TYPES.T_NORTH
    elseif not adjacent[EAST] then
      return TILE_TYPES.T_WEST
    else
      return TILE_TYPES.T_EAST
    end
  else
    -- 4-way crossing
    return TILE_TYPES.CROSS
  end
end

--- Analyzes a path and returns the appropriate tile type for each cell
---@param path vibes.Path The path to analyze
---@return table<string, string> A map of cell keys to tile types
function PathAnalyzer.analyze_path(path)
  local results = {}
  local cells = path.cells

  for i, cell in ipairs(cells) do
    local tile_type = determine_tile_type(cell, cells)
    local cell_key = cell.row .. "," .. cell.col
    results[cell_key] = tile_type
  end

  return results
end

--- Get the appropriate quad name for a tile type
---@param tile_type string The tile type
---@return string The quad name to use
function PathAnalyzer.get_quad_name(tile_type)
  return TILE_TO_QUAD[tile_type] or "center"
end

--- Analyzes multiple paths and returns a unified tile map
---@param paths vibes.Path[] The paths to analyze
---@return table<string, string> A map of cell keys to tile types
function PathAnalyzer.analyze_paths(paths)
  local combined_results = {}
  local all_cells = {}

  -- Combine all cells from all paths
  for _, path in ipairs(paths) do
    for _, cell in ipairs(path.cells) do
      table.insert(all_cells, cell)
    end
  end

  -- Analyze each cell with all possible connections
  for _, cell in ipairs(all_cells) do
    local tile_type = determine_tile_type(cell, all_cells)
    local cell_key = cell.row .. "," .. cell.col
    combined_results[cell_key] = tile_type
  end

  return combined_results
end

--- Get the rotation angle for a specific tile type
---@param tile_type string The tile type
---@return number The rotation in radians
function PathAnalyzer.get_rotation_for_tile(tile_type)
  -- Define rotations for tile types that need them
  local rotations = {
    [TILE_TYPES.VERTICAL] = math.pi / 2, -- 90 degrees
    [TILE_TYPES.END_WEST] = math.pi, -- 180 degrees
    [TILE_TYPES.END_NORTH] = math.pi / 2, -- 90 degrees
    [TILE_TYPES.END_SOUTH] = -math.pi / 2, -- -90 degrees
  }

  return rotations[tile_type] or 0
end

--- Get the tile type for a cell position
---@param cell_key string The cell key in format "row,col"
---@param tile_map table<string, string> The tile map from analyze_paths
---@return string The tile type or nil if not found
function PathAnalyzer.get_tile_type_for_cell(cell_key, tile_map)
  return tile_map[cell_key]
end

--- Get debug info about a tile
---@param tile_type string The tile type
---@return string Debug info
function PathAnalyzer.get_tile_debug_info(tile_type)
  local quad_name = TILE_TO_QUAD[tile_type] or "unknown"
  local rotation = PathAnalyzer.get_rotation_for_tile(tile_type)

  return string.format(
    "%s\n%s\nrot: %.1f",
    tile_type,
    quad_name,
    rotation * 180 / math.pi -- convert to degrees for readability
  )
end

return PathAnalyzer
