local Container = require "ui.components.container"
local PackCard = require "ui.components.pack.card"
local Text = require "ui.components.text"

---@class (exact) components.PackSelection.Opts
---@field box? ui.components.Box
---@field pack vibes.CardPack
---@field on_confirm fun(card: vibes.Card)
---@field on_cancel fun()

---@class (exact) components.PackSelection : Element
---@field init fun(self: components.PackSelection, opts: components.PackSelection.Opts)
---@field new fun(opts: components.PackSelection.Opts): components.PackSelection
---@field pack vibes.CardPack
---@field _layout layout.Layout
---@field _selected_card vibes.Card?
---@field _on_confirm fun(card: vibes.Card)
---@field _on_cancel fun()
local PackSelection = class("components.PackSelection", { super = Element })

function PackSelection:init(opts)
  validate(opts, {
    pack = "table", -- vibes.CardPack
    on_confirm = "function",
    on_cancel = "function",
    box = "ui.components.Box?",
  })

  self.pack = opts.pack
  self._on_confirm = opts.on_confirm
  self._on_cancel = opts.on_cancel

  local box = Box.fullscreen()
  Element.init(self, box, {
    interactable = true,
    z = Z.SHOP_PACK_OVERLAY,
  })

  self:_set_layout()
end

function PackSelection:_set_layout()
  local _, _, w, h = self:get_geo()

  local card_elements = {}
  local cards_w = (w * 0.55) -- Reduced from 0.70 to make cards smaller
  local card_w = (cards_w / #self.pack.cards)

  if #self.pack.cards < 3 then
    card_w = Config.ui.card.width * 0.8 -- Make cards smaller even for small packs
  end

  for idx, card in ipairs(self.pack.cards) do
    table.insert(
      card_elements,
      PackCard.new {
        box = Box.new(Position.zero(), card_w - 40, Config.ui.card.height),
        card = card,
        on_click = function()
          -- Immediately confirm the selection without requiring a separate confirm step
          self._selected_card = card

          -- Update selection state for visual feedback (briefly)
          for card_idx, card_el in ipairs(card_elements) do
            if card_idx == idx then
              card_el:set_selected(true)
            else
              card_el:set_selected(false)
            end
          end

          -- Immediately confirm the selection
          self._on_confirm(self._selected_card)
          self._selected_card = nil

          return UIAction.HANDLED
        end,
        on_blur = function(el) el:set_scale(0.8) end,
        on_focus = function(el) el:set_scale(1) end,
        on_selection_change = function(card_element, selected)
          -- No longer needed since we confirm immediately on click
        end,
      }
    )
  end

  -- Center everything properly using percentages
  local center_x = w / 2
  local center_y = h / 2

  -- Pack title - centered at top
  local title_text = Text.new {
    function() return self.pack.name .. " Opened!" end,
    text_align = "center",
    color = Colors.white:get(),
    font = Asset.fonts.typography.h1,
    box = Box.new(
      Position.new(60, center_y - 300),
      Config.window_size.width - 120,
      100
    ),
  }

  self:append_child(title_text)

  -- Pack description - below title
  local desc_text = Text.new {
    function() return self.pack.description end,
    text_align = "center",
    color = Colors.white:get(),
    font = Asset.fonts.typography.paragraph_md,
    box = Box.new(Position.new(center_x - 400, center_y - 200), 800, 60),
  }

  self:append_child(desc_text)

  -- Background rectangle for cards - centered
  local card_bg_width = cards_w + 200
  local card_bg_height = 500
  local card_bg = Container.new {
    box = Box.new(
      Position.new(center_x - card_bg_width / 2, center_y - 50),
      card_bg_width,
      card_bg_height
    ),
    background = { 1, 1, 1, 0.1 },
    name = "CardBackground",
    interactable = true,
  }
  self:append_child(card_bg)

  -- Center the cards horizontally
  local total_cards_width = (card_w * #self.pack.cards)
    + (30 * (#self.pack.cards - 1))
  local cards_start_x = center_x - total_cards_width / 2

  for idx, card in ipairs(self.pack.cards) do
    local card_x = cards_start_x + (idx - 1) * (card_w + 30)
    local card_element = card_elements[idx]
    card_element:set_scale(0.8)
    card_element:set_pos(Position.new(card_x, center_y - 70))
    self:append_child(card_element)
  end
end

function PackSelection:_render() end

return PackSelection
