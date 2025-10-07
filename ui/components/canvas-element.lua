local Container = require "ui.components.container"

--- A CanvasElement renders all of its children to a canvas once, then displays
--- that canvas. This is useful for performance optimization when you have many
--- children that don't change often, as it avoids re-rendering them every frame.
---
--- Example usage:
--- ```lua
--- local CanvasElement = require "ui.components.canvas-element"
--- local Container = require "ui.components.container"
--- local Text = require "ui.components.text"
---
--- local canvas_el = CanvasElement.new {
---   box = Box.new(Position.new(100, 100), 200, 150),
---   background_color = { 0.2, 0.2, 0.2, 1 }, -- Optional gray background
--- }
---
--- -- Add some child elements that will be rendered to the canvas
--- local text = Text.new {
---   "Static Content",
---   box = Box.new(Position.new(10, 10), 180, 30),
---   color = { 1, 1, 1, 1 }
--- }
--- canvas_el:append_child(text)
---
--- -- The canvas will automatically invalidate and re-render when children change
--- ```
---@class (exact) components.CanvasElement : Element
---@field new fun(opts: components.CanvasElement.Opts): components.CanvasElement
---@field init fun(self: components.CanvasElement, opts: components.CanvasElement.Opts)
---@field _canvas love.Canvas?
---@field needs_redraw boolean
---@field background_color? number[]
---@field _canvas_element Container?
---@field _children_to_render Element[]
local CanvasElement = class("ui.components.CanvasElement", { super = Element })

---@class (exact) components.CanvasElement.Opts
---@field box ui.components.Box
---@field background_color? number[] Optional background color [r, g, b, a] (0-1 range)
---@field z? number
---@field hidden? boolean
---@field debug? boolean

---@param opts components.CanvasElement.Opts
function CanvasElement:init(opts)
  validate(opts, {
    box = Box,
    background_color = "table?",
    z = "number?",
    hidden = "boolean?",
    debug = "boolean?",
  })

  Element.init(self, opts.box, {
    z = opts.z,
    hidden = opts.hidden,
    debug = opts.debug,
    draggable = true,
  })

  self.name = "CanvasElement"

  -- Create the actual canvas that we want to render to.
  self._canvas = self:_create_canvas()

  -- Create a fake element to hold the canvas, so child calculations are correct.
  self._canvas_element = Container.new {
    box = Box.new(
      Position.zero(),
      self._canvas:getWidth(),
      self._canvas:getHeight()
    ),
  }

  self._children_to_render = {}

  self.needs_redraw = true
  self.background_color = opts.background_color
end

--- Creates a new canvas with the current dimensions
function CanvasElement:_create_canvas()
  local _, _, width, height = self:get_geo()

  if width <= 0 or height <= 0 then
    return nil
  end

  return love.graphics.newCanvas(width, height)
end

--- Marks the canvas as needing a redraw
function CanvasElement:invalidate() self.needs_redraw = true end

--- Override append_child to invalidate canvas when children change
---@param el Element
function CanvasElement:append_child(el)
  self:invalidate()

  el.parent = self._canvas_element
  table.insert(self._children_to_render, el)
end

--- Override remove_child to invalidate canvas when children change
---@param el Element
---@param hint number?
function CanvasElement:remove_child(el, hint)
  self:invalidate()

  el.parent = nil
  for i, child in ipairs(self._children_to_render) do
    if child == el then
      table.remove(self._children_to_render, i)
    end
  end
end

--- Override remove_all_children to invalidate canvas
function CanvasElement:remove_all_children()
  self:invalidate()
  while #self._children_to_render > 0 do
    self:remove_child(self._children_to_render[#self._children_to_render])
  end
end

--- Renders all children to the canvas
function CanvasElement:_render_to_canvas()
  love.graphics.push "all"
  love.graphics.origin()

  love.graphics.setCanvas { self._canvas, stencil = true }
  love.graphics.clear()

  for _, child in ipairs(self._children_to_render) do
    local ok, err = pcall(child.render, child)
    if not ok then
      print(string.format("Error rendering child %s: %s", child, err))
    end
  end

  love.graphics.setCanvas()
  love.graphics.pop()

  self.needs_redraw = false
end

--- Override update to check if canvas needs recreation due to size changes
---@param dt number
function CanvasElement:update(dt)
  Element.update(self, dt)

  for _, child in ipairs(self._children_to_render) do
    child:update(dt)
  end

  -- Check if canvas needs recreation due to size change
  if self._canvas then
    -- TODO: This probably isn't right, because these will change based on parent's size.
    --    It doesn't account for scaling.
    --
    -- local canvas_width = self.canvas:getWidth()
    -- local canvas_height = self.canvas:getHeight()
    -- local current_width = self:get_width()
    -- local current_height = self:get_height()

    -- if canvas_width ~= current_width or canvas_height ~= current_height then
    --   self.canvas:release()
    --   self.canvas = nil
    --   self.needs_redraw = true
    -- end
  end
end

function CanvasElement:_render()
  assert(self._canvas, "CanvasElement:canvas is nil")

  -- if self.needs_redraw or true then
  self:_render_to_canvas()

  -- Draw the canvas if it exists
  local color = { unpack(self:get_color()) }
  color[4] = self:get_opacity()

  love.graphics.setColor(unpack(color))
  local canvas_x, canvas_y, _, _ = self.parent:get_geo()
  love.graphics.draw(self._canvas, canvas_x, canvas_y)

  -- local x, y, w, h = self:get_geo()
  -- love.graphics.setColor(1, 0, 0, 1)
  -- love.graphics.rectangle("line", x, y, w, h)
end

function CanvasElement:_click()
  self:animate_style(
    { scale = self:get_scale() / 2, rotation = 0 },
    { duration = 3 }
  )
  return UIAction.HANDLED
end

--- Clean up the canvas when the element is no longer needed
function CanvasElement:destroy()
  if self._canvas then
    self._canvas:release()
    self._canvas = nil
  end
end

return CanvasElement
