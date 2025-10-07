local CardElement = require "ui.components.card"
local ReactiveList = require "ui.mixins.reactive-list"

local MARGIN = 40
local CARD_WIDTH = Config.ui.card.new_width * 0.4
local CARD_HEIGHT = Config.ui.card.new_height * 0.4

---@class CardKindList.Opts
---@field cards vibes.Card[]
---@field kind CardKind
---@field box ui.components.Box
---@field on_card_select fun(card:vibes.Card)

---@class (exact) CardKindList : layout.Layout, mixin.ReactiveList
---@field new fun(opts: CardKindList.Opts): CardKindList
---@field init fun(self: CardKindList, opts: CardKindList.Opts)
---@field cards vibes.Card[]
---@field kind CardKind
---@field _on_card_select fun(card:vibes.Card)
local CardKindList = class("ui.components.CardKindList", {
  super = Layout,
  mixin = { ReactiveList },
})

---@param opts CardKindList.Opts
function CardKindList:init(opts)
  validate(opts, {
    cards = List { Card },
    kind = CardKind,
    box = Box,
  })
  self._on_card_select = opts.on_card_select
  self.cards = opts.cards
  self.kind = opts.kind

  Layout.init(self, {
    name = "CardKindList(" .. opts.kind .. ")",
    box = opts.box,
    flex = {
      direction = "row",
      justify_content = "start",
      align_items = "start",
      gap = (MARGIN / 4),
    },
    animation_duration = 0,
  })
end

function CardKindList:get_reactive_list()
  local filtered_cards = {}
  for _, card in ipairs(self.cards) do
    if card.kind == self.kind then
      table.insert(filtered_cards, card)
    end
  end
  self.flex.gap =
    self:calculate_overlap(self:get_width(), CARD_WIDTH, #filtered_cards, 0)
  return filtered_cards
end

function CardKindList:create_element_for_item(card, state)
  local c = CardElement.new {
    card = card,
    box = Box.new(Position.new(0, 0), CARD_WIDTH, CARD_HEIGHT),
    disable_check = true,
    on_use = function() end,
    on_click = function()
      if self._on_card_select then
        self._on_card_select(card)
      end
    end,
  }
  return c
end
function CardKindList:calculate_overlap(
  containerWidth,
  elementWidth,
  elementCount,
  startX
)
  startX = startX or 0

  local totalElementWidth = elementWidth * elementCount

  if totalElementWidth <= containerWidth then
    return 10
  else
    local excess = totalElementWidth - containerWidth
    local negativeOverlap = -excess

    if elementCount > 1 then
      local maxNegativeOverlap = (containerWidth - elementWidth)
          / (elementCount - 1)
        - elementWidth
      return math.max(negativeOverlap, maxNegativeOverlap)
    else
      return negativeOverlap
    end
  end
end

function CardKindList:_update() self:_update_z_indexing() end

function CardKindList:_update_z_indexing()
  --- TODO: this needs to be better, this is a quick fix. tried doing this
  --- directly in Elements and Layout it keeps getting overwritten
  for index, value in ipairs(self.reactive_container.children) do
    value.z = Z.OVERLAY + index
  end
end
function CardKindList:_render() Layout._render(self) end

return CardKindList
