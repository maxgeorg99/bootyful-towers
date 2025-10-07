local BaseCard = require "ui.components.card"
local TowerTooltip = require "ui.components.tower.elements.tooltip"

---@class components.ShopCard.Opts : components.Card.Opts
---@field on_hover_start? fun(card: components.ShopCardElement)
---@field on_hover_end? fun(card: components.ShopCardElement)

---@class (exact) components.ShopCardElement : components.Card
---@field new fun(opts: components.ShopCard.Opts): components.ShopCardElement
---@field init fun(self: components.ShopCardElement, opts: components.ShopCard.Opts)
---@field _tower_tooltip? components.TowerTooltip
---@field _tower_card? vibes.TowerCard
---@field _on_hover_start? fun(card: components.ShopCardElement)
---@field _on_hover_end? fun(card: components.ShopCardElement)
local ShopCard = class("components.ShopCardElement", { super = BaseCard })

---@param opts components.ShopCard.Opts
function ShopCard:init(opts)
  validate(opts, {
    on_hover_start = "function?",
    on_hover_end = "function?",
  })

  -- Initialize parent first
  BaseCard.init(self, opts)

  ---@diagnostic disable-next-line undefined-field
  self.z = F.if_nil(opts.z, Z.SHOP_INTERACTABLES)
  self.hide_level = true
  -- Set up shop card specific state
  self._on_hover_start = opts.on_hover_start
  self._on_hover_end = opts.on_hover_end
  self.name = "ShopCardElement"

  -- Set up tower tooltip if this is a tower card
  local tower_card = self.card:get_tower_card()
  if tower_card then
    -- Store the tower card reference for later tooltip creation
    self._tower_card = tower_card
  end
end

--- Override focus to show tooltip for tower cards
function ShopCard:_focus(evt)
  -- Call parent focus handler first
  if self._on_focus then
    self:_on_focus(evt)
  end

  -- Call custom hover start callback
  if self._on_hover_start then
    self._on_hover_start(self)
  end

  -- Show tower tooltip on focus if this is a tower card
  if self._tower_card and not self._tower_tooltip then
    -- Create tooltip positioned above the card
    local _, _, card_w, card_h = self:get_geo()
    local card_box = Box.new(Position.new(0, 0), card_w, card_h)

    self._tower_tooltip = TowerTooltip.new {
      card = self._tower_card,
      tower_box = card_box,
      z = Z.SHOP_TOWER_TOOLTIP,
    }
    self._tower_tooltip:set_opacity(0)
    self._tower_tooltip.pointer_placement = TooltipPlacement.BOTTOM

    -- Position the tooltip above the card using absolute coordinates
    local card_x, card_y, _, _ = self:get_geo()
    local _, _, tooltip_w, tooltip_h = self._tower_tooltip:get_geo()
    local tooltip_x = card_x + (card_w - tooltip_w) / 2
    local tooltip_y = card_y - tooltip_h - 40

    self._tower_tooltip:set_pos(Position.new(tooltip_x, tooltip_y))
  end

  if self._tower_tooltip then
    -- Parent tooltip to root UI element to avoid z-index inheritance issues
    self:append_child(self._tower_tooltip)
    self._tower_tooltip:enter_from_tower()
  end

  -- Add slight scale animation for visual feedback
  self:animate_style({ scale = 1.05 }, { duration = 0.1 })

  return UIAction.HANDLED
end

function ShopCard:_blur(evt)
  BaseCard._blur(self, evt)

  -- Call custom hover end callback
  if self._on_hover_end then
    self._on_hover_end(self)
  end

  -- Hide tooltip
  if self._tower_tooltip then
    self._tower_tooltip:exit_tower()
    self:remove_child(self._tower_tooltip)
    self._tower_tooltip = nil
  end

  -- Reset scale animation
  self:animate_style({ scale = 1.0 }, { duration = 0.1 })

  return UIAction.HANDLED
end

function ShopCard:__tostring()
  return string.format("ShopCardElement(%s)", BaseCard.__tostring(self))
end

return ShopCard
