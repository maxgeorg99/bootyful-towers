local CardElement = require "ui.components.card"
local DropZone = require "ui.mixins.drop-zone"

---@class components.TowerCardSlot : Element, mixin.DropZone
---@field new fun(opts: components.TowerCardSlot.Opts):components.TowerCardSlot
---@field init fun(self: components.TowerCardSlot, opts: components.TowerCardSlot.Opts)
---@field card? vibes.Card
local TowerCardSlot =
  class("components.TowerCardSlot", { super = Element, mixin = { DropZone } })

---@class components.TowerCardSlot.Opts
---@field box ui.components.Box
---@field card? vibes.Card

function TowerCardSlot:init(opts)
  validate(opts, {
    box = Box,
    card = "vibes.Card?",
  })

  Element.init(self, opts.box, { z = Z.CARD_SLOT + 100, interactable = true })

  if Card.is(opts.card) then
    local c = CardElement.new { box = opts.box:clone(), card = opts.card }
    self:append_child(c)
  end
end

function TowerCardSlot:_render()
  local x, y, w, h = self:get_geo()
  love.graphics.setLineWidth(3)
  local color = Colors.white
  if self:dropzone_is_hovering() then
    color = Colors.red
  end

  self:with_color(
    color,
    function() love.graphics.rectangle("line", x, y, w, h, 10, 10, 80) end
  )
end

-- [[ Drop Zone Functions
--- @param element components.Card?
function TowerCardSlot:_dropzone_accepts_element(element)
  return element
    and CardElement.is(element)
    and EnhancementCard.is(element.card)
end

---@param element components.Card
function TowerCardSlot:_dropzone_on_start(element) return UIAction.HANDLED end

function TowerCardSlot:_dropzone_on_drop(element) return UIAction.HANDLED end

---@param element components.Card
function TowerCardSlot:_dropzone_on_finish(element) return UIAction.HANDLED end
-- ]]

return TowerCardSlot
