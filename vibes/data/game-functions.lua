local GameFunctions = {}

---@param position vibes.Position
---@param radius number in cells
---@return vibes.Enemy[]
function GameFunctions.enemies_within(position, radius)
  local radius_squared = radius * radius
  local radius_sq_pxs = radius_squared * Config.grid.cell_size
  local enemies = {}
  for _, enemy in ipairs(State.enemies) do
    if enemy.position:distance_squared(position) <= radius_sq_pxs then
      table.insert(enemies, enemy)
    end
  end

  table.sort(
    enemies,
    function(a, b)
      return a.position:distance_squared(position)
        < b.position:distance_squared(position)
    end
  )

  return enemies
end

---@return vibes.Tower?
function GameFunctions.get_tower_from_mouseover_cell()
  local cell = GameFunctions.get_cell_from_mouse()
  for _, tower in ipairs(State.towers) do
    if tower.cell == cell then
      return tower
    end
  end
  return nil
end

--- @return vibes.Cell
function GameFunctions.get_cell_from_mouse()
  local g_row, g_col = Cell.to_cell_coordinates(State.mouse)
  local cells = State.levels:get_current_level().cells
  if not cells[g_row + 1] then
    return Cell.new(0, 0)
  end
  return cells[g_row + 1][g_col + 1]
end

---@param cell vibes.Cell
---@param tower vibes.Tower
function GameFunctions.draw_tower_range(cell, tower)
  local half_cell_size = Config.grid.cell_size / 2

  if not tower:can_place(cell) then
    return
  end

  local center_x = cell.col * Config.grid.cell_size + half_cell_size
  local center_y = cell.row * Config.grid.cell_size + half_cell_size
  local radius = tower:get_range_in_distance()

  -- Handle towers with zero range (like support towers)
  if radius <= 0 then
    -- For support towers, show a small indicator at the tower position
    if tower.tower_type == TowerKind.SUPPORT then
      love.graphics.setColor(0, 0.7, 0, 0.8)
      -- Draw a small circle around the tower position
      love.graphics.circle("line", center_x, center_y, half_cell_size * 1.2)
      love.graphics.setLineWidth(3)
      love.graphics.circle("line", center_x, center_y, half_cell_size * 0.8)
      love.graphics.setLineWidth(1)

      -- Draw range icon at the tower position
      love.graphics.setColor(1, 1, 1, 1)
      local icon = Asset.icons[IconType.RANGE]
      local icon_size = 32
      local icon_x = center_x - icon_size / 2
      local icon_y = center_y - icon_size / 2
      love.graphics.draw(
        icon,
        icon_x,
        icon_y,
        0,
        icon_size / icon:getWidth(),
        icon_size / icon:getHeight()
      )
    end
    return
  end

  love.graphics.setColor(0, 0.7, 0, 0.8)

  -- Calculate number of dots based on circumference
  -- Space dots roughly every 12 pixels
  local circumference = 2 * math.pi * radius
  local dot_spacing = 12
  local num_dots = math.floor(circumference / dot_spacing)

  -- Draw dots around the circle
  for i = 0, num_dots - 1 do
    local angle = (i / num_dots) * 2 * math.pi
    local x = center_x + radius * math.cos(angle)
    local y = center_y + radius * math.sin(angle)

    -- Every 5th dot is larger
    local dot_radius = (i % 5 == 0) and 4.5 or 2.5

    love.graphics.circle("fill", x, y, dot_radius)
  end

  -- Draw range icon at the top of the circle
  love.graphics.setColor(1, 1, 1, 1)
  local icon = Asset.icons[IconType.RANGE]
  local icon_size = 64
  local icon_x = center_x - icon_size / 2
  local icon_y = center_y - radius - icon_size / 2
  love.graphics.draw(
    icon,
    icon_x,
    icon_y,
    0,
    icon_size / icon:getWidth(),
    icon_size / icon:getHeight()
  )
end

---@param cell vibes.Cell
---@param tower vibes.Tower
function GameFunctions.draw_tower_preview(cell, tower)
  tower.cell = cell
  tower.position = Position.from_cell(cell)

  -- love.graphics.setColor(1, 1, 1, 0.5)
  tower:draw { preview = true }
end

---@param tower vibes.Tower
---@return components.PlacedTower?
function GameFunctions.get_placed_tower_from_tower(tower)
  for _, el in ipairs(UI.root.children) do
    if el._type == "components.PlacedTower" then
      local placed_tower = el --[[@as components.PlacedTower]]
      if tower.id == placed_tower.tower.id then
        return placed_tower
      end
    end
  end
  return nil
end

return GameFunctions
