---@class (exact) ui.components.UIRootElement : Element
---@field new fun(): ui.components.UIRootElement
---@field init fun(self: ui.components.UIRootElement)
---@field super Element
local UIRootElement = class("ui.UIRootElement", { super = Element })

function UIRootElement:init()
  local width = Config.window_size.width
  local height = Config.window_size.height
  local box = Box.new(Position.new(0, 0), width, height)
  Element.init(self, box)

  self.name = "Root"
  self.z = 0
end

function UIRootElement:_render() end

return UIRootElement
