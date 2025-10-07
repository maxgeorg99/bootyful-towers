local CanvasElement = require "ui.components.canvas-element"

---@class components.CanvasTest.Opts
---@field box ui.components.Box

---@class components.CanvasTest : Element
---@field new fun(opts: components.CanvasTest.Opts)
---@field init fun(self:components.CanvasTest, opts:components.CanvasTest.Opts)
local CanvasTest = class("components.CanvasTest", { super = Element })

---@return components.CanvasTest
function CanvasTest:init(opts)
  Element.init(self, opts.box, { interactable = true })
  local width = Config.ui.card.width
  local height = Config.ui.card.height

  local canvas_box = Box.new(Position.new(0, 0), width, height)

  self._canvas_element = CanvasElement.new {
    box = canvas_box,
    background_color = Colors.white,
  }

  Element.append_child(self, self._canvas_element)

  self._canvas_element:set_scale(1)
end
function CanvasTest:append_canvas_child(child)
  self._canvas_element:append_child(child)
end

function CanvasTest:remove_canvas_child(child)
  self._canvas_element:remove_child(child)
end

function CanvasTest:_mouse_enter() end
function CanvasTest:_mouse_leave() end

function CanvasTest:close() end

function CanvasTest:_update(_dt) end

function CanvasTest:_render() end

return CanvasTest
