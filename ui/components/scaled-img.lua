--- Auto scaled imaged to fit inside of the box.
---@class (exact) component.ScaledImg : Element
---@field new fun(opts: component.ScaledImg.Opts): component.ScaledImg
---@field init fun(self: self, component.ScaledImg.Opts)
---@field texture vibes.Texture
---@field scale_style "fit" | "fill" | "stretch"
---@field scale_x number
---@field _on_click? fun(self: component.ScaledImg): UIAction?
local ScaledImage = class("component.ScaledImg", { super = Element })

---@class component.ScaledImg.Opts: Element.Opts
---@field box ui.components.Box
---@field texture vibes.Texture
---@field scale_style "fit" | "fill" | "stretch"
---@field interactable? boolean
---@field on_click? fun(self: component.ScaledImg): UIAction?
---@field shaders? Element.Shader[]

---@param opts component.ScaledImg.Opts
function ScaledImage:init(opts)
  opts.scale_style = opts.scale_style or "fit"

  validate(opts, {
    box = Box,
    texture = "userdata",
    scale_style = "string",
  })

  Element.init(self, opts.box, {
    interactable = F.if_nil(opts.interactable, false),
  })

  self.name = "ScaledImage"
  self.texture = opts.texture
  self.scale_style = opts.scale_style
  self._on_click = opts.on_click

  -- Initialize shaders if provided
  if opts.shaders then
    self.shaders = opts.shaders
  end
end

function ScaledImage:_render()
  local x, y, w, h = self:get_geo()

  local texture_w = self.texture:getWidth()
  local texture_h = self.texture:getHeight()

  local scale_x = w / texture_w
  local scale_y = h / texture_h
  self.scale_x = scale_x
  if self.scale_style == "stretch" then
  elseif self.scale_style == "fill" then
    scale_x = math.max(scale_x, scale_y)
    scale_y = math.max(scale_x, scale_y)
  elseif self.scale_style == "fit" then
    scale_x = math.min(scale_x, scale_y)
    scale_y = math.min(scale_x, scale_y)
  end

  -- print(scale_x, scale_y, scale)
  x = x + (w - texture_w * scale_x) / 2
  y = y + (h - texture_h * scale_y) / 2

  self:with_color(
    Colors.white,
    function() love.graphics.draw(self.texture, x, y, 0, scale_x, scale_y) end
  )
end

function ScaledImage:_click()
  if self._on_click then
    return self._on_click(self)
  end
end

return ScaledImage
