local ReactiveList = require "ui.mixins.reactive-list"

---@class components.ForgePile.Opts
---@field cards vibes.Card[]
---@field place_card fun(ui_card: components.Card)

---@class (exact) components.ForgePile : Element, mixin.ReactiveList
---@field new fun(opts: components.ForgePile.Opts): components.ForgePile
---@field init fun(self: components.ForgePile, opts: components.ForgePile.Opts)
---@field cards vibes.Card[]
---@field place_card fun(ui_card: components.Card)
local ForgePileElement = class("components.ForgePileElement", {
  super = Element,
  mixin = { ReactiveList },
})

---@param opts components.ForgePile.Opts
function ForgePileElement:init(opts)
  validate(opts, {
    cards = List { Card },
    place_card = "function",
  })

  local box =
    Box.from(0, 0, Config.window_size.width, Config.window_size.height)
  Element.init(self, box)
  self.cards = opts.cards
  self.place_card = opts.place_card

  local container_width = Config.window_size.width * 0.8

  self.name = "ForgeUI-pile-container"
  self.get_reactive_list = function() return opts.cards end
  self.create_element_for_item = function(_, card, _)
    return self:_create_card_from_item(card)
  end

  self.reactive_container = Layout.row {
    name = "ForgeUI-pile",
    box = Box.new(
      Position.new(
        0.1 * Config.window_size.width,
        Config.window_size.height - Config.ui.card.new_height * 1.2
      ),
      container_width,
      Config.ui.card.new_height
    ),
  }
  self:append_child(self.reactive_container)
  self.z = Z.FORGE_PILE
end

---@param ui_card components.Card
function ForgePileElement:return_to_pile(ui_card)
  table.insert(self.cards, ui_card.card)
end

---@param ui_card components.Card
function ForgePileElement:remove_from_pile(ui_card)
  local card = ui_card.card
  for i, c in ipairs(self.cards) do
    if c.id == card.id then
      table.remove(self.cards, i)
      break
    end
  end
end

---@param card vibes.Card
---@return Element
function ForgePileElement:_create_card_from_item(card)
  local CardElement = require "ui.components.card"
  local function on_focus(c, _) c.z = Z.FORGE_PILE_CARD_TOP end
  local function on_blur(c, _) c.z = Z.FORGE_PILE_CARD end

  local card_config = Config.ui.card
  local ui_card = CardElement.new {
    z = Z.FORGE_PILE_CARD,
    card = card,
    on_use = function() end,
    on_focus = on_focus,
    on_blur = on_blur,
    on_click = self.place_card,
    box = Box.new(
      Position.new(0, 0),
      card_config.new_width,
      card_config.new_height
    ),
  }
  ui_card.z = Z.FORGE_PILE_CARD
  ui_card:set_draggable(false)
  return ui_card
end

function ForgePileElement:_render() end

return ForgePileElement
