local LowerThird = class("ui.components.LowerThird", { super = Element })

function LowerThird:init(opts)
  validate(opts, {})

  Element.init(self, Box.fullscreen())

  self.texture = Asset.sprites.lower_third
end

function LowerThird:_render()
  local x, y, w, h = self:get_geo()
  love.graphics.draw(
    self.texture,
    x,
    y,
    0,
    w / self.texture:getWidth(),
    h / self.texture:getHeight()
  )
end

return LowerThird
