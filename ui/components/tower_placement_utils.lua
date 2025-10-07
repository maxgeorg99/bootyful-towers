local M = {}

---@param tower vibes.Tower
function M.tower_to_ui_box(tower)
  local w = tower.texture:getWidth() * Config.tower.scale
  local h = tower.texture:getHeight() * Config.tower.scale
  local position = tower.cell:center()
  local tower_pos = position:sub(Position.new((w / 2), h - 25))

  return Box.new(tower_pos, w, h)
end

function M.tower_offset(position, cell)
  return Position.new(
    position.x,
    position.y - Config.grid.cell_size * 0.3 - cell.height
  )
end

return M
