local ButtonElement = require "ui.elements.button"
local Text = require "ui.components.text"
local TrophyCard = require "ui.components.trophy.card"

local CardFactory = require "vibes.factory.card-factory"

-- UI Layout constants
local DEFAULT_W = Config.window_size.width
local DEFAULT_H = Config.window_size.height
local CARD_WIDTH = Config.ui.card.new_width -- Smaller width
local CARD_HEIGHT = Config.ui.card.new_height -- Much smaller height (1/3)
local CARD_SPACING = 40 -- Reduced spacing to fit better

---@class components.trophy.CardsTrophyUI.Opts
---@field on_complete? fun(): nil
---@field rarity Rarity?
---@field is_trophy boolean?

---@class (exact) components.trophy.CardsTrophyUI : Element
---@field new fun(opts: components.trophy.CardsTrophyUI.Opts): components.trophy.CardsTrophyUI
---@field init fun(self: components.trophy.CardsTrophyUI, opts: components.trophy.CardsTrophyUI.Opts)
---@field trophy_cards vibes.Card[]
---@field _selected vibes.Card | nil
---@field _card_elements components.TrophyCard[]
---@field _skip_button elements.Button
---@field _on_complete? fun(): nil
---@field rarity Rarity?
---@field is_trophy boolean?
local CardsTrophyUI =
  class("components.trophy.CardsTrophyUI", { super = Element })

---@param opts components.trophy.CardsTrophyUI.Opts
function CardsTrophyUI:init(opts)
  validate(opts, {
    on_complete = "function?",
    rarity = "Rarity?",
    is_trophy = "boolean?",
  })

  local box = Box.new(Position.new(0, 0), DEFAULT_W, DEFAULT_H)

  Element.init(self, box, {
    z = Z.TROPHY_SELECTION_CARDS,
    interactable = false, -- Let children handle interactions
    created_offset = Position.new(0, Config.window_size.height),
  })

  self.name = "CardsTrophyUI"
  self._selected = nil
  self._card_elements = {}
  self._on_complete = opts.on_complete
  self.rarity = opts.rarity
  self.is_trophy = opts.is_trophy

  self:_generate_trophy_cards()
  self:_add_layout()
end

--- Generate 3 trophy cards
function CardsTrophyUI:_generate_trophy_cards()
  self.trophy_cards = {}

  while #self.trophy_cards < 3 do
    local card = nil
    if self.rarity then
      card = CardFactory.get_trophy_card_by_rarity(self.rarity)
    else
      card = CardFactory.new_trophy_card()
    end

    local seen = false
    for _, c in ipairs(self.trophy_cards) do
      if c.name == card.name then
        seen = true
        break
      end
    end
    if not seen then
      table.insert(self.trophy_cards, card)
    end
  end
end

function CardsTrophyUI:_add_layout()
  local _, _, w, h = self:get_geo()

  -- Create card elements
  for idx, card in ipairs(self.trophy_cards) do
    local card_element = TrophyCard.new {
      box = Box.new(Position.zero(), CARD_WIDTH, CARD_HEIGHT),
      card = card,
      z = Z.TROPHY_SELECTION_CARDS,
      on_click = function() return self:_select_card(idx, card) end,
    }

    table.insert(self._card_elements, card_element)
  end

  -- Create skip button
  self._skip_button = ButtonElement.new {
    box = Box.new(Position.zero(), 200, 60),
    label = "Skip Selection",
    on_click = function() self:_skip_selection() end,
  }

  -- Create the main layout
  local main_layout = Layout.new {
    name = "CardsTrophySelection",
    box = Box.new(Position.zero(), w, h),
    animation_duration = 0,
    els = {
      -- Title section
      Layout.col {
        animation_duration = 0,
        box = Box.new(Position.zero(), w, 150),
        els = {
          Layout.rectangle {
            h = 80,
            w = 100,
          },
          Text.new {
            function() return "Click one card to add to your deck!" end,
            text_align = "center",
            color = Colors.white:get(),
            font = Asset.fonts.typography.h2,
            box = Box.new(Position.zero(), w, 60),
          },
        },
        flex = {
          direction = "column",
          justify_content = "center",
          align_items = "center",
          gap = 30,
        },
      },

      -- Cards section
      Layout.new {
        name = "TrophyCards",
        box = Box.new(Position.zero(), w, 500),
        els = self._card_elements,
        animation_duration = 0,
        flex = {
          direction = "row",
          justify_content = "center",
          align_items = "center",
          gap = CARD_SPACING,
        },
      },

      -- Skip button section
      Layout.new {
        name = "TrophyButtons",
        box = Box.new(Position.zero(), w, 100),
        z = Z.TROPHY_SELECTION_BUTTONS,
        animation_duration = 0,
        els = {
          self._skip_button,
        },
        flex = {
          direction = "row",
          justify_content = "center",
          align_items = "center",
          gap = 40,
        },
      },
    },
    flex = {
      direction = "column",
      justify_content = "center",
      align_items = "center",
      gap = 40,
    },
  }

  self:append_child(main_layout)
end

--- Handle card selection and immediate confirmation
---@param idx number
---@param card vibes.Card
---@return UIAction
function CardsTrophyUI:_select_card(idx, card)
  -- Immediately confirm the selection without requiring a separate confirm step
  self._selected = card

  -- Update selection state for visual feedback (briefly)
  for card_idx, card_el in ipairs(self._card_elements) do
    if card_idx == idx then
      card_el:set_selected(true)
    else
      card_el:set_selected(false)
    end
  end

  -- Immediately confirm the selection
  self:_confirm_selection()

  return UIAction.HANDLED
end

--- Confirm the trophy selection
function CardsTrophyUI:_confirm_selection()
  if not self._selected then
    return
  end

  -- Handle card selection - add to deck
  State.deck:add_card(self._selected)
  EventBus:emit_card_gained {
    card = self._selected,
  }
  logger.info("Trophy card selected: %s", self._selected.name)

  self:_complete_trophy_selection()
end

--- Skip trophy selection
function CardsTrophyUI:_skip_selection()
  logger.info "Trophy selection skipped"
  self:_complete_trophy_selection()
end

--- Complete the trophy selection
function CardsTrophyUI:_complete_trophy_selection()
  if self._on_complete then
    self._on_complete()
  end
end

function CardsTrophyUI:_render() end

function CardsTrophyUI:__tostring() return "CardsTrophyUI" end

return CardsTrophyUI
