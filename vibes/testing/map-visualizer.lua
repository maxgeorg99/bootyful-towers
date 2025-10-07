---@diagnostic disable

---@class vibes.testing.MapVisualizerOptions
---@field output_path string Path to save the generated image
---@field cell_size number Size of each cell in pixels
---@field show_scores boolean Whether to show placement scores

---@class (exact) vibes.testing.MapVisualizer : vibes.Class
---@field new fun(opts: vibes.testing.MapVisualizerOptions): vibes.testing.MapVisualizer
---@field init fun(self: vibes.testing.MapVisualizer, opts: vibes.testing.MapVisualizerOptions)
---@field output_path string
---@field cell_size number
---@field show_scores boolean
local MapVisualizer = class "vibes.testing.MapVisualizer"

---@param opts vibes.testing.MapVisualizerOptions
function MapVisualizer:init(opts)
  validate(opts, {
    output_path = "string",
    cell_size = "number?",
    show_scores = "boolean?",
  })

  self.output_path = opts.output_path
  self.cell_size = opts.cell_size or 20
  self.show_scores = opts.show_scores or false
end

--- Generate a visualization of the current game state
---@param simulation_result vibes.testing.SimulationResult
---@param config vibes.testing.SimulationConfig
function MapVisualizer:generate_map_image(simulation_result, config)
  local level = State.levels:get_current_level()
  if not level or not level.cells then
    logger.warn "MapVisualizer: No level or cells available for visualization"
    return
  end

  local grid_width = Config.grid.grid_width
  local grid_height = Config.grid.grid_height
  local img_width = grid_width * self.cell_size
  local img_height = grid_height * self.cell_size

  -- Create a canvas to draw on
  local canvas = love.graphics.newCanvas(img_width, img_height)
  love.graphics.setCanvas(canvas)
  love.graphics.clear(0.2, 0.2, 0.2, 1) -- Dark gray background

  -- Draw the grid
  self:_draw_grid(level, grid_width, grid_height)

  -- Draw paths
  self:_draw_paths(level)

  -- Draw towers
  self:_draw_towers()

  -- Add legend
  self:_draw_legend(simulation_result, config)

  -- Reset canvas
  love.graphics.setCanvas()

  -- Save the image
  local imageData = canvas:newImageData()
  imageData:encode("png", self.output_path)

  logger.info("MapVisualizer: Saved map visualization to %s", self.output_path)

  -- Clean up
  canvas:release()
  imageData:release()
end

--- Draw the grid cells
---@param level vibes.Level
---@param grid_width number
---@param grid_height number
function MapVisualizer:_draw_grid(level, grid_width, grid_height)
  for row = 1, grid_height do
    for col = 1, grid_width do
      local cell = level.cells[row] and level.cells[row][col]
      if cell then
        local x = (col - 1) * self.cell_size
        local y = (row - 1) * self.cell_size

        -- Color based on cell type
        if cell.is_path then
          love.graphics.setColor(0.8, 0.6, 0.4, 1) -- Brown for path
        elseif cell.is_placeable then
          love.graphics.setColor(0.4, 0.6, 0.4, 1) -- Green for placeable
        else
          love.graphics.setColor(0.3, 0.3, 0.3, 1) -- Dark gray for non-placeable
        end

        love.graphics.rectangle("fill", x, y, self.cell_size, self.cell_size)

        -- Draw grid lines
        love.graphics.setColor(0.1, 0.1, 0.1, 1) -- Dark lines
        love.graphics.rectangle("line", x, y, self.cell_size, self.cell_size)
      end
    end
  end
end

--- Draw enemy paths
---@param level vibes.Level
function MapVisualizer:_draw_paths(level)
  if not level.paths then
    return
  end

  love.graphics.setColor(1, 0.8, 0.2, 1) -- Yellow for path
  love.graphics.setLineWidth(3)

  for _, path in pairs(level.paths) do
    if path.cells and #path.cells > 1 then
      for i = 1, #path.cells - 1 do
        local current_cell = path.cells[i]
        local next_cell = path.cells[i + 1]

        local x1 = (current_cell.col + 0.5) * self.cell_size
        local y1 = (current_cell.row + 0.5) * self.cell_size
        local x2 = (next_cell.col + 0.5) * self.cell_size
        local y2 = (next_cell.row + 0.5) * self.cell_size

        love.graphics.line(x1, y1, x2, y2)
      end

      -- Draw path start (green circle)
      if #path.cells > 0 then
        local start_cell = path.cells[1]
        local start_x = (start_cell.col + 0.5) * self.cell_size
        local start_y = (start_cell.row + 0.5) * self.cell_size
        love.graphics.setColor(0, 1, 0, 1) -- Green
        love.graphics.circle("fill", start_x, start_y, self.cell_size * 0.3)
      end

      -- Draw path end (red circle)
      if #path.cells > 0 then
        local end_cell = path.cells[#path.cells]
        local end_x = (end_cell.col + 0.5) * self.cell_size
        local end_y = (end_cell.row + 0.5) * self.cell_size
        love.graphics.setColor(1, 0, 0, 1) -- Red
        love.graphics.circle("fill", end_x, end_y, self.cell_size * 0.3)
      end
    end
  end
end

--- Draw placed towers
function MapVisualizer:_draw_towers()
  if not State.towers then
    return
  end

  for i, tower in ipairs(State.towers) do
    if tower.cell then
      local x = (tower.cell.col + 0.5) * self.cell_size
      local y = (tower.cell.row + 0.5) * self.cell_size

      -- Draw tower range circle (light blue, transparent)
      love.graphics.setColor(0.3, 0.7, 1, 0.3)
      local range = tower:get_range_in_distance()
      local range_pixels = range * (self.cell_size / Config.grid.cell_size)
      love.graphics.circle("fill", x, y, range_pixels)

      -- Draw tower (blue circle)
      love.graphics.setColor(0.2, 0.4, 1, 1) -- Blue
      love.graphics.circle("fill", x, y, self.cell_size * 0.4)

      -- Draw tower border
      love.graphics.setColor(1, 1, 1, 1) -- White border
      love.graphics.setLineWidth(2)
      love.graphics.circle("line", x, y, self.cell_size * 0.4)

      -- Draw tower number
      love.graphics.setColor(1, 1, 1, 1) -- White text
      local font = love.graphics.getFont()
      local text = tostring(i)
      local text_width = font:getWidth(text)
      local text_height = font:getHeight()
      love.graphics.print(text, x - text_width / 2, y - text_height / 2)

      -- Show placement score if enabled
      if self.show_scores then
        local AIStrategy = require "vibes.testing.ai-strategy"
        local level = State.levels:get_current_level()
        local score = AIStrategy.evaluate_cell_for_placement(tower.cell, level)
        love.graphics.setColor(1, 1, 0, 1) -- Yellow text
        local score_text = string.format("%.0f", score)
        love.graphics.print(
          score_text,
          x - text_width / 2,
          y + self.cell_size * 0.6
        )
      end
    end
  end
end

--- Draw legend and simulation info
---@param simulation_result vibes.testing.SimulationResult
---@param config vibes.testing.SimulationConfig
function MapVisualizer:_draw_legend(simulation_result, config)
  local legend_x = 10
  local legend_y = 10
  local line_height = 20
  local y = legend_y

  -- Semi-transparent background for legend
  love.graphics.setColor(0, 0, 0, 0.7)
  love.graphics.rectangle("fill", legend_x - 5, legend_y - 5, 300, 200)

  love.graphics.setColor(1, 1, 1, 1) -- White text
  local font = love.graphics.getFont()

  -- Simulation info
  love.graphics.print(string.format("Seed: %d", config.seed), legend_x, y)
  y = y + line_height
  love.graphics.print(
    string.format("Strategy: %s", config.strategy),
    legend_x,
    y
  )
  y = y + line_height
  love.graphics.print(
    string.format("Rounds: %d", simulation_result.rounds_completed),
    legend_x,
    y
  )
  y = y + line_height
  love.graphics.print(
    string.format("Towers: %d", simulation_result.towers_placed),
    legend_x,
    y
  )
  y = y + line_height
  love.graphics.print(
    string.format("Cards: %d", simulation_result.cards_played),
    legend_x,
    y
  )
  y = y + line_height + 10

  -- Legend
  love.graphics.print("Legend:", legend_x, y)
  y = y + line_height

  -- Path legend
  love.graphics.setColor(1, 0.8, 0.2, 1)
  love.graphics.rectangle("fill", legend_x, y, 15, 15)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print("Enemy Path", legend_x + 20, y)
  y = y + line_height

  -- Tower legend
  love.graphics.setColor(0.2, 0.4, 1, 1)
  love.graphics.circle("fill", legend_x + 7, y + 7, 7)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print("Tower", legend_x + 20, y)
  y = y + line_height

  -- Range legend
  love.graphics.setColor(0.3, 0.7, 1, 0.3)
  love.graphics.circle("fill", legend_x + 7, y + 7, 7)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print("Tower Range", legend_x + 20, y)
  y = y + line_height

  -- Start/End legend
  love.graphics.setColor(0, 1, 0, 1)
  love.graphics.circle("fill", legend_x + 7, y + 7, 5)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print("Path Start", legend_x + 20, y)
  y = y + line_height

  love.graphics.setColor(1, 0, 0, 1)
  love.graphics.circle("fill", legend_x + 7, y + 7, 5)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print("Path End", legend_x + 20, y)
end

return MapVisualizer
