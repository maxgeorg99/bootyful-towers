---@alias ui.components.PlaceBox.Priority "top" | "left" | "right" | "bottom"

---@class ui.components.PlaceBox.Opts
---@field padding? number
---@field priority? string[]  -- validated at runtime to ui.components.PlaceBox.Priority[]

-- ===== Defaults =================================================================

local cell_size = Config.grid.cell_size
local exlusion_height = cell_size * 2

local DEFAULT_PADDING = 10
local DEFAULT_PRIORITIES = { "top", "bottom", "left", "right" }

local MIN_X = 0
local MIN_Y = cell_size * 2
local MAX_X = Config.window_size.width
local MAX_Y = Config.window_size.height - cell_size * 3.1

-- ===== Public ===================================================================

local function clamp_with_padding(value, min, max, length, padding)
  return math.max(min + padding, math.min(value, max - length - padding))
end

local function is_valid(box, next_to)
  if box:intersects(next_to) then
    return false
  end

  return true
end

--- Place a box next to another box with padding
---@param placed_box ui.components.Box The box to position
---@param next_to ui.components.Box The box to position next to
---@param opts? ui.components.PlaceBox.Opts Options including padding and priority
---@return ui.components.Box, ui.components.PlaceBox.Priority
local function place_box(placed_box, next_to, opts)
  opts = opts or {}
  local padding = opts.padding or DEFAULT_PADDING
  local priority = opts.priority or DEFAULT_PRIORITIES

  if padding <= 0 then
    padding = 1
  end

  local first_box = nil
  local first_priority = nil
  assert(#priority > 0, "No priority provided")

  for _, priority in ipairs(priority) do
    if priority == "top" then
      local final_x = next_to.position.x
        + (next_to.width - placed_box.width) / 2
      local final_y = next_to.position.y - placed_box.height - padding

      final_x =
        clamp_with_padding(final_x, MIN_X, MAX_X, placed_box.width, padding)
      final_y =
        clamp_with_padding(final_y, MIN_Y, MAX_Y, placed_box.height, padding)

      local potential_box = Box.new(
        Position.new(final_x, final_y),
        placed_box.width,
        placed_box.height
      )
      if not potential_box:intersects(next_to) then
        return potential_box, priority
      end
    elseif priority == "bottom" then
      local final_x = next_to.position.x
        + (next_to.width - placed_box.width) / 2
      local final_y = next_to.position.y + next_to.height + padding

      final_x =
        clamp_with_padding(final_x, MIN_X, MAX_X, placed_box.width, padding)
      final_y =
        clamp_with_padding(final_y, MIN_Y, MAX_Y, placed_box.height, padding)

      local potential_box = Box.new(
        Position.new(final_x, final_y),
        placed_box.width,
        placed_box.height
      )
      if not potential_box:intersects(next_to) then
        return potential_box, priority
      end
    elseif priority == "left" then
      local final_x = next_to.position.x - placed_box.width - padding
      local final_y = next_to.position.y
        + (next_to.height - placed_box.height) / 2

      final_x =
        clamp_with_padding(final_x, MIN_X, MAX_X, placed_box.width, padding)
      final_y =
        clamp_with_padding(final_y, MIN_Y, MAX_Y, placed_box.height, padding)

      local potential_box = Box.new(
        Position.new(final_x, final_y),
        placed_box.width,
        placed_box.height
      )
      if not potential_box:intersects(next_to) then
        return potential_box, priority
      end
    elseif priority == "right" then
      local final_x = next_to.position.x + next_to.width + padding
      local final_y = next_to.position.y
        + (next_to.height - placed_box.height) / 2

      final_x =
        clamp_with_padding(final_x, MIN_X, MAX_X, placed_box.width, padding)
      final_y =
        clamp_with_padding(final_y, MIN_Y, MAX_Y, placed_box.height, padding)

      local potential_box = Box.new(
        Position.new(final_x, final_y),
        placed_box.width,
        placed_box.height
      )
      if not potential_box:intersects(next_to) then
        return potential_box, priority
      end
    end
  end

  assert(false, "No valid placement found")
end

return {
  position = place_box,
  DEFAULT_PADDING = DEFAULT_PADDING,
  DEFAULT_PRIORITIES = DEFAULT_PRIORITIES,
}
