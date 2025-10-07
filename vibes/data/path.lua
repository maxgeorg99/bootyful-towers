---@class vibes.Path : vibes.Class
---@field new fun(opts: vibes.Path.Options): vibes.Path
---@field init fun(self: vibes.Path, opts: vibes.Path.Options)
---@field cells vibes.Cell[] Array of cells defining the path
---@field id string
---@field total_distance number The total distance of the path
local Path = class "vibes.path"

---@class vibes.Path.Options
---@field cells vibes.Cell[] Array of cells defining the path
---@field id string

---@param opts vibes.Path.Options
function Path:init(opts)
  validate(opts, {
    cells = "table",
    id = "string",
  })

  self.cells = opts.cells
  self.id = opts.id

  local total_distance = 0
  for i = 1, #self.cells - 1 do
    local pos1 = Position.from_cell(self.cells[i])
    local pos2 = Position.from_cell(self.cells[i + 1])
    total_distance = total_distance + pos1:sub(pos2):magnitude()
  end

  self.total_distance = total_distance
end

function Path:__tostring()
  local cells_str = ""
  for _, cell in ipairs(self.cells) do
    cells_str = string.format("%s, %s", cells_str, cell)
  end
  return string.format("Path(%s)", cells_str)
end

--- Get all cells that enemies will traverse along this path
--- Uses the same interpolation logic as enemy movement
---@return vibes.Cell[]
function Path:get_all_traversed_cells()
  local traversed_cells = {}
  local cell_set = {} -- To avoid duplicates

  for i = 1, #self.cells - 1 do
    local start_cell = self.cells[i]
    local end_cell = self.cells[i + 1]

    local start_pos = Position.from_cell(start_cell)
    local end_pos = Position.from_cell(end_cell)

    -- Sample the path at regular intervals (like enemy movement)
    local segment_distance = start_pos:distance(end_pos)
    local sample_step = Config.grid.cell_size / 2 -- Half cell size for good coverage
    local num_samples = math.ceil(segment_distance / sample_step)

    for sample = 0, num_samples do
      local t = sample / num_samples -- Interpolation factor 0-1
      local sample_pos = start_pos:add(end_pos:sub(start_pos):scale(t))
      local sample_cell = Cell.from_position(sample_pos)

      local cell_key = sample_cell.row .. "," .. sample_cell.col
      if not cell_set[cell_key] then
        cell_set[cell_key] = true
        table.insert(traversed_cells, sample_cell)
      end
    end
  end

  return traversed_cells
end

return Path
