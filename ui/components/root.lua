local NoopElement = require "ui.components.noop"

---@class (exact) ui.components.RootElement : Element
---@field new fun(width: number, height: number): ui.components.RootElement
---@field init fun(self: ui.components.RootElement, width: number, height: number)
---@field super Element
---@field tooltip_root Element
---@field absolute_tooltip Element?
---@field show_absolute_tooltip fun(self: ui.components.RootElement, content: Element, x: number, y: number)
---@field hide_absolute_tooltip fun(self: ui.components.RootElement)
local RootElement = class("ui.components.RootElement", { super = Element })

--- @param width number
---@param height number
function RootElement:init(width, height)
  local box = Box.new(Position.new(0, 0), width, height)
  Element.init(self, box, {
    interactable = true,
    draggable = false,
  })

  local tooltip_root = NoopElement.new(box)

  self.name = "Root"
  self.tooltip_root = tooltip_root
  tooltip_root.z = Z.MAX + 1
  tooltip_root.name = "Tooltip"

  self.absolute_tooltip = nil
end

--- @param tooltip Element
function RootElement:append_tooltip(tooltip)
  -- TODO(TJ): I would like to remove this,
  -- we do not need this abstraction anymore IMO
  self.tooltip_root:append_child(tooltip)
end

--- @param tooltip Element
function RootElement:remove_tooltip(tooltip)
  self.tooltip_root:remove_child(tooltip)
end

--- Show an absolute positioned tooltip
---@param content Element The element to show as a tooltip
---@param x number Absolute x position
---@param y number Absolute y position
function RootElement:show_absolute_tooltip(content, x, y)
  -- Hide any existing absolute tooltip
  self:hide_absolute_tooltip()

  -- Set the tooltip's position to absolute coordinates
  content._props.x = x
  content._props.y = y

  -- Set z-index to render on top of everything
  content.z = Z.MAX + 2

  self.absolute_tooltip = content
end

--- Hide the absolute positioned tooltip
function RootElement:hide_absolute_tooltip() self.absolute_tooltip = nil end

function RootElement:_render()
  self.tooltip_root:render()

  -- Render absolute tooltip if it exists
  if self.absolute_tooltip then
    self.absolute_tooltip:render()
  end
end

function RootElement:_update(dt)
  -- Sepcial notice, root element should always set itself to 0
  ---@diagnostic disable-next-line
  self.state._depth = 0
end

return RootElement
