local PADDING = 8

---@alias ui.components.Tooltip.Placement "NEAR_ELEMENT" | "CENTER_SCREEN" | "WINDOW_TOP_CENTER" |nil

---@class (exact) ui.components.Tooltip : Element
---@field new fun(text: string, el: Element, width: number, placement: ui.components.Tooltip.Placement?, timeout: number?): ui.components.Tooltip
---@field init fun(self: ui.components.Tooltip, text: string, el: Element, width: number, placement: ui.components.Tooltip.Placement?, timeout: number?)
---@field super Element
---@field _type "ui.components.Tooltip"
---@field text string
---@field font love.Font
---@field display_width number
---@field lines string[]
---@field timeout number?
---@field timer number?
local Tooltip = class("ui.components.Tooltip", { super = Element })

--- @TODO make it so that text is either a string or an element.  that way a
--- tooltip can display either aligned text OR a nice beautiful tower stats
--- @param text string
--- @param el Element
--- @param width number
--- @param placement ui.components.Tooltip.Placement?
--- @param timeout number? Time in seconds before tooltip auto-hides
function Tooltip:init(text, el, width, placement, timeout)
  placement = placement or "NEAR_ELEMENT"
  Element.init(self, Box.empty())

  self.name = "Tooltip"
  self.display_width = width
  self.text = text
  self.font = Asset.fonts.typography.h3
  self.timeout = timeout
  self.timer = timeout -- Start timer if timeout is provided

  --- @NOTE Order matters
  self:set_width(width + PADDING * 2)
  self:_fit_text()
  self:set_height(
    (self.font:getHeight() + PADDING / 2) * #self.lines -- + (PADDING * 2)
  )

  self:_set_position(el, placement)
end

--- @param el Element
---@param placement ui.components.Tooltip.Placement
function Tooltip:_set_position(el, placement)
  assert(Element.is(el), "must provide an element")
  assert(self.lines, "lines must be set to call _set_position")
  local _, _, self_w, self_h = self:get_geo()
  assert(self_h ~= 0, "tooltip must have a height to call _set_position")

  local x, y, width, height = el:get_geo()

  if placement == "CENTER_SCREEN" then
    local cx = Config.window_size.width / 2
    local cy = Config.window_size.height / 2
    self:set_pos(Position.new(cx - self_w / 2, cy - self_h / 2))
    return
  elseif placement == "WINDOW_TOP_CENTER" then
    local cx = Config.window_size.width / 2
    local cy = 35
    self:set_pos(Position.new(cx - self_w / 2, cy - self_h / 2))
  elseif placement == "NEAR_ELEMENT" then
    -- attempt left first
    local _, _, el_w, el_h = el:get_geo()
    local start_x = x + el_w + PADDING
    local middle_y = y + el_h / 2

    if
      start_x + width < Config.window_size.width
      and middle_y + height / 2 < Config.window_size.height
    then
      self:set_pos(Position.new(start_x, middle_y - height / 2))
      return
    end
  end

  -- assert(false, "Object is out of bounds")
end

local function split_text(text)
  local out = {}
  --- split by space
  for word in text:gmatch "%S+" do
    table.insert(out, word)
  end
  return out
end

function Tooltip:_fit_text()
  self.lines = {}

  local words = split_text(self.text)
  local current_line = ""
  for _, word in ipairs(words) do
    if self.font:getWidth(current_line .. " " .. word) > self.display_width then
      table.insert(self.lines, current_line)
      current_line = word
    else
      current_line = current_line .. " " .. word
    end
  end
  if current_line ~= "" then
    table.insert(self.lines, current_line)
  end
end

function Tooltip:_update(dt)
  -- Handle timeout if set
  if self.timer and self.timer > 0 then
    self.timer = self.timer - dt
    if self.timer <= 0 then
      -- Auto-hide tooltip when timer expires
      if self.parent then
        self.parent:remove_child(self)
      end
    end
  end
end

function Tooltip:_render()
  local x, y, width, height = self:get_geo()
  love.graphics.push()
  love.graphics.setFont(self.font)
  love.graphics.setColor(Colors.red:opacity(0.8))

  love.graphics.rectangle("fill", x, y, width, height + 15, 10, 10, 80)

  love.graphics.setColor(Colors.white)

  for i, line in ipairs(self.lines) do
    love.graphics.printf(
      line,
      x,
      y + PADDING + (i - 1) * (self.font:getHeight() + PADDING / 2),
      width,
      "center"
    )
  end
  love.graphics.pop()
end

return Tooltip
