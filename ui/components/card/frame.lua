local ScaledImage = require "ui.components.scaled-img"

---@class components.CardFrame.Opts
---@field card vibes.Card
---@field box ui.components.Box

---@class components.CardFrame : Element
---@field init fun(self: components.CardFrame, opts:components.CardFrame.Opts)
---@field new fun(opts:components.CardFrame.Opts)
---@field card vibes.Card
local CardFrame = class("components.CardFrame", { super = Element })

function CardFrame:init(opts)
  validate(opts, {
    card = Card,
    box = Box,
  })

  Element.init(self, opts.box)

  self.card = opts.card

  local x, y, w, h = self:get_geo()

  local frame = ScaledImage.new {
    box = Box.new(Position.zero(), w, h),
    texture = Asset.sprites.generated.card_frames[self.card.rarity],
    scale_style = "stretch",
  }

  self:append_child(frame)
end

function CardFrame:_mouse_enter() end
function CardFrame:_mouse_leave() end
function CardFrame:_render()
  -- local asset = Asset.sprites.generated.card_frames[self.card.rarity]
  -- local x, y, w, h = self:get_geo()
  -- love.graphics.setColor(Colors.white:opacity(self:get_opacity()))
  --
  -- local scale_x = w / asset:getWidth()
  -- local scale_y = h / asset:getHeight()
  -- local scale = math.max(scale_x, scale_y)
  --
  -- love.graphics.draw(asset, x, y, 0, scale, scale)
end

return CardFrame
