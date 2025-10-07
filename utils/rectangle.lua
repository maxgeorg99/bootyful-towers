local M = {}

--- Draws text in the center of a rectangle
---@param text string
---@param x number
---@param y number
---@param width number
---@param height number
---@param opacity? number
function M.center_text_in_rectangle(text, x, y, width, height, opacity)
  if not opacity then
    opacity = 1
  end
  love.graphics.setColor(1, 1, 1, opacity)
  local font = love.graphics.getFont()
  local textHeight = font:getHeight()

  local centerY = y + (height - textHeight) / 2

  love.graphics.printf(text, x, centerY, width, "center")
end

---@param x number
---@param y number
---@param width number
---@param height number
---@param dash_length? number
---@param gap_length? number
---@param animation_offset? number
function M.dashed_rectangle(
  x,
  y,
  width,
  height,
  dash_length,
  gap_length,
  animation_offset
)
  dash_length = dash_length or 10
  gap_length = gap_length or 5
  animation_offset = animation_offset or 0

  local segment_length = dash_length + gap_length

  local function draw_dashed_segment(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    local distance = math.sqrt(dx * dx + dy * dy)

    if distance == 0 then
      return
    end

    local unit_x = dx / distance
    local unit_y = dy / distance

    local current_distance = -animation_offset % segment_length

    while current_distance < distance do
      if
        (current_distance + animation_offset) % segment_length < dash_length
      then
        local start_distance = math.max(current_distance, 0)
        local end_distance = math.min(
          current_distance
            + dash_length
            - ((current_distance + animation_offset) % segment_length),
          distance
        )

        if end_distance > start_distance then
          local start_x = x1 + start_distance * unit_x
          local start_y = y1 + start_distance * unit_y
          local end_x = x1 + end_distance * unit_x
          local end_y = y1 + end_distance * unit_y

          love.graphics.line(start_x, start_y, end_x, end_y)
        end
      end
      current_distance = current_distance + segment_length
    end
  end

  draw_dashed_segment(x, y, x + width, y)
  draw_dashed_segment(x + width, y, x + width, y + height)
  draw_dashed_segment(x + width, y + height, x, y + height)
  draw_dashed_segment(x, y + height, x, y)
end

return M
