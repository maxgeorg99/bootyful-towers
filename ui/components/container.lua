local Anim = require "vibes.anim"

---@class Container.Props : Element.Props
---@field background? number[]
---
--- A container is an element that can contain other elements, it doesn't
--- do anything else, but it's specifically made for just holding elements
---@class Container : Element
---@field new fun(opts: Container.Opts): Container
---@field init fun(self: Container, opts: Container.Opts)
---@field on_click? fun(): nil | boolean
---@field background? number[]
---@field hover_background? number[]
---@field _props Container.Props : Element.Props
local Container = class("ui.components.Container", { super = Element })

---@class Container.Opts : Element.Opts
---@field box ui.components.Box
---@field background? number[]
---@field hover_background? number[]
---@field draw_mode? "fill" | "line"
---@field els? Element[]
---@field on_click? fun(): nil | boolean

---@param opts Container.Opts
function Container:init(opts)
  Element.init(self, opts.box, opts)

  self.draw_mode = opts.draw_mode or "fill"
  self.background = opts.background
  self.on_click = opts.on_click

  if opts.els then
    for _, el in ipairs(opts.els) do
      self:append_child(el)
    end
  end

  if opts.hover_background then
    validate(opts, {
      hover_background = "table",
      background = "table",
    })
    self.hover_background = opts.hover_background
    self.targets.background = self.background
    Anim.extend(self.animator, {
      background = {
        initial = self.background,
        rate = 1,
      },
    })
  end
end

function Container:_render()
  local x, y, w, h = self:get_geo()

  if self.hover_background then
    love.graphics.setColor(self._props.background)
    love.graphics.rectangle(self.draw_mode, x, y, w, h)
    love.graphics.setColor(1, 1, 1, 1)
  elseif self.background then
    love.graphics.setColor(self.background)
    love.graphics.rectangle(self.draw_mode, x, y, w, h)
    love.graphics.setColor(1, 1, 1, 1)
  end
end

function Container:_update()
  if self.hover_background then
    if self:is_entered() then
      self.targets.background = self.hover_background
    else
      self.targets.background = self.background
    end
  end
end

function Container:_click()
  if self.on_click then
    return self.on_click()
  end
end

return Container
