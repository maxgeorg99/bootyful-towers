local CardSlot = require "ui.components.tower.elements.card-slot"
local ReactiveList = require "ui.mixins.reactive-list"

---@class (exact) components.TowerCardSlots.Opts
---@field box? ui.components.Box
---@field placed_tower components.PlacedTower

---@class (exact) components.TowerCardSlots : layout.Layout , mixin.ReactiveList, Element
---@field new fun( opts: components.TowerCardSlots.Opts): components.TowerCardSlots
---@field init fun(self: components.TowerCardSlots, opts: components.TowerCardSlots.Opts)
---@field placed_tower components.PlacedTower
---@field cards vibes.EnhancementCard[]
---@field set_card_dragging fun(self:components.TowerCardSlots, card:components.Card?)
---@field _card_dragging components.Card?
---@field _on_drag_start fun(self, card:components.Card)
---@field _on_drag_end fun(self, card:components.Card)
local TowerCardSlots = class(
  "ui.components.tower.TowerCardSlots",
  { super = Layout, mixin = { ReactiveList } }
)

function TowerCardSlots:init(opts)
  validate(opts, {
    box = Box,
    placed_tower = "components.PlacedTower",
    on_drag_complete = "function?",
  })

  if not opts.box then
    opts.box = Box.new(Position.new(0, 400), Config.window_size.width, 150)
  end
  self.placed_tower = opts.placed_tower

  Layout.init(self, {
    name = "TowerCardSlots(Layout)",
    box = opts.box,
    flex = {
      gap = 20,
      direction = "row",
      justify_content = "center",
      align_items = "center",
    },
  })
  self:set_interactable(true)
  self:set_hidden(true)
  self:set_z(Z.CARD_SLOTS + 1)
end

function TowerCardSlots:get_reactive_list()
  local cards = {}
  table.list_extend(cards, self.placed_tower.tower.enhancements)

  if self.placed_tower.tower:has_free_card_slot() then
    --- create some sort of a noop card for the reactive list
    --- if card slots are available
    table.insert(cards, { id = #self.reactive_container.children + 1 })
  end

  return cards
end

function TowerCardSlots:create_element_for_item(enhancment)
  return CardSlot.new {
    box = Box.new(Position.zero(), 110, 150),
    card = enhancment,
  }
end

function TowerCardSlots:_update(dt) Layout._render(self) end

function TowerCardSlots:set_card_dragging(card)
  local card_slot =
    self.reactive_container.children[#self.reactive_container.children] --[[@as components.TowerCardSlot]]

  if card_slot and card_slot:dropzone_accepts_element(card) then
    card_slot:dropzone_on_start(card)
  end
end

function TowerCardSlots:_on_drag_start(card)
  local card_slot =
    self.reactive_container.children[#self.reactive_container.children] --[[@as components.TowerCardSlot]]
  if card_slot and card_slot:dropzone_accepts_element(card) then
    card_slot:dropzone_on_start(card)
  end
end

function TowerCardSlots:_on_drag_end(card)
  local card_slot =
    self.reactive_container.children[#self.reactive_container.children] --[[@as components.TowerCardSlot]]
  if card_slot then
    card_slot:dropzone_on_finish(card)
  end
end

return TowerCardSlots
