---@diagnostic disable

---@class vibes.testing.TextMapVisualizerOptions
---@field output_path string Path to save the generated text map
---@field show_scores boolean Whether to show placement scores

---@class (exact) vibes.testing.TextMapVisualizer : vibes.Class
---@field new fun(opts: vibes.testing.TextMapVisualizerOptions): vibes.testing.TextMapVisualizer
---@field init fun(self: vibes.testing.TextMapVisualizer, opts: vibes.testing.TextMapVisualizerOptions)
---@field output_path string
---@field show_scores boolean
local TextMapVisualizer = class "vibes.testing.TextMapVisualizer"

---@param opts vibes.testing.TextMapVisualizerOptions
function TextMapVisualizer:init(opts)
  validate(opts, {
    output_path = "string",
    show_scores = "boolean?",
  })

  self.output_path = opts.output_path
  self.show_scores = opts.show_scores or false
end

--- Generate a text-based visualization of the current game state
---@param simulation_result vibes.testing.SimulationResult
---@param config vibes.testing.SimulationConfig
function TextMapVisualizer:generate_map_text(simulation_result, config)
  local level = simulation_result.level_data or State.levels:get_current_level()
  if not level or not level.cells then
    logger.warn "TextMapVisualizer: No level or cells available for visualization"
    return
  end

  local grid_width = Config.grid.grid_width
  local grid_height = Config.grid.grid_height

  -- Create a 2D array to represent the map
  local map = {}
  for row = 1, grid_height do
    map[row] = {}
    for col = 1, grid_width do
      map[row][col] = self:_get_cell_character(level, row, col)
    end
  end

  -- Add towers to the map
  self:_add_towers_to_map(map, simulation_result.towers_data)

  -- Add paths to the map
  self:_add_paths_to_map(map, level)

  -- Generate the text output
  local output = {}
  table.insert(output, "=" .. string.rep("=", 79))
  table.insert(output, "TOWER PLACEMENT VISUALIZATION")
  table.insert(output, "=" .. string.rep("=", 79))
  table.insert(
    output,
    string.format(
      "Seed: %d | Strategy: %s | Rounds: %d",
      config.seed,
      config.placement_strategy or "balanced",
      simulation_result.rounds_completed
    )
  )
  table.insert(
    output,
    string.format(
      "Towers: %d | Cards: %d | Final Health: %d",
      simulation_result.towers_placed,
      simulation_result.cards_played,
      simulation_result.final_health
    )
  )
  table.insert(output, "")

  -- Add column numbers header
  local header = "   "
  for col = 1, grid_width do
    header = header .. string.format("%2d", col % 100)
  end
  table.insert(output, header)

  -- Add the map
  for row = 1, grid_height do
    local line = string.format("%2d ", row)
    for col = 1, grid_width do
      line = line .. map[row][col] .. " "
    end
    table.insert(output, line)
  end

  table.insert(output, "")
  table.insert(output, "LEGEND:")
  table.insert(output, "  . = Empty/Non-placeable")
  table.insert(output, "  # = Placeable ground")
  table.insert(output, "  ~ = Path")
  table.insert(output, "  S = Path start")
  table.insert(output, "  E = Path end")
  table.insert(output, "  T = Tower (numbered)")
  table.insert(output, "  R = Tower range coverage")

  if self.show_scores then
    table.insert(output, "")
    table.insert(output, "TOWER PLACEMENT SCORES:")
    self:_add_tower_scores(output, simulation_result.towers_data, level)
  end

  table.insert(output, "")
  table.insert(output, "=" .. string.rep("=", 79))

  -- Write to file
  local file = io.open(self.output_path, "w")
  if file then
    file:write(table.concat(output, "\n"))
    file:close()
    logger.info(
      "TextMapVisualizer: Saved map visualization to %s",
      self.output_path
    )
  else
    logger.error("TextMapVisualizer: Failed to write to %s", self.output_path)
  end
end

--- Get the character representation for a cell
---@param level vibes.Level
---@param row number
---@param col number
---@return string
function TextMapVisualizer:_get_cell_character(level, row, col)
  local cell = level.cells[row] and level.cells[row][col]
  if not cell then
    return "."
  end

  if cell.is_path then
    return "~"
  elseif cell.is_placeable then
    return "#"
  else
    return "."
  end
end

--- Add towers to the map visualization
---@param map string[][]
---@param towers_data table?
function TextMapVisualizer:_add_towers_to_map(map, towers_data)
  local towers = towers_data or State.towers
  if not towers then
    logger.warn "TextMapVisualizer: No towers found for visualization"
    return
  end

  logger.debug("TextMapVisualizer: Found %d towers to place", #towers)

  for i, tower in ipairs(towers) do
    if tower.cell then
      -- Convert from 0-based cell coordinates to 1-based map array coordinates
      local row = tower.cell.row + 1
      local col = tower.cell.col + 1

      logger.debug(
        "TextMapVisualizer: Placing tower %d at row=%d, col=%d (cell coords: %d,%d)",
        i,
        row,
        col,
        tower.cell.row,
        tower.cell.col
      )

      -- Ensure coordinates are within map bounds
      if row >= 1 and row <= #map and col >= 1 and col <= #map[1] then
        -- Place tower number (use single digit, wrapping at 9)
        map[row][col] = tostring(i % 10)

        -- Show tower range (simplified - use default archer range)
        local range_cells = 3.9 -- Default archer tower range
        for r = math.max(1, row - range_cells), math.min(#map, row + range_cells) do
          for c = math.max(1, col - range_cells), math.min(#map[1], col + range_cells) do
            -- Only mark empty placeable cells within range
            if map[r] and map[r][c] == "#" then
              local distance = math.sqrt((r - row) ^ 2 + (c - col) ^ 2)
              if distance <= range_cells then
                map[r][c] = "R"
              end
            end
          end
        end
      else
        logger.warn(
          "TextMapVisualizer: Tower %d coordinates (%d,%d) are out of bounds",
          i,
          row,
          col
        )
      end
    end
  end
end

--- Add path markers to the map
---@param map string[][]
---@param level vibes.Level
function TextMapVisualizer:_add_paths_to_map(map, level)
  if not level.paths then
    return
  end

  for _, path in pairs(level.paths) do
    if path.cells and #path.cells > 0 then
      -- Mark path start
      local start_cell = path.cells[1]
      local start_row = start_cell.row + 1
      local start_col = start_cell.col + 1
      if map[start_row] and map[start_row][start_col] then
        map[start_row][start_col] = "S"
      end

      -- Mark path end
      local end_cell = path.cells[#path.cells]
      local end_row = end_cell.row + 1
      local end_col = end_cell.col + 1
      if map[end_row] and map[end_row][end_col] then
        map[end_row][end_col] = "E"
      end
    end
  end
end

--- Add tower placement scores to output
---@param output string[]
---@param towers_data table?
---@param level vibes.Level
function TextMapVisualizer:_add_tower_scores(output, towers_data, level)
  local towers = towers_data or State.towers
  if not towers then
    return
  end

  local AIStrategy = require "vibes.testing.ai-strategy"

  for i, tower in ipairs(towers) do
    if tower.cell then
      local score = AIStrategy.evaluate_cell_for_placement(tower.cell, level)
      table.insert(
        output,
        string.format(
          "  Tower %d at (%d,%d): Score %.0f",
          i,
          tower.cell.row + 1,
          tower.cell.col + 1,
          score
        )
      )
    end
  end
end

return TextMapVisualizer
