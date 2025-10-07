local BaseCard = require "ui.components.card"

---@class components.TrophyCard.Opts : components.Card.Opts
---@field on_selection_change? fun(card: components.TrophyCard, selected: boolean)

---@class (exact) components.TrophyCard : components.Card
---@field new fun(opts: components.TrophyCard.Opts): components.TrophyCard
---@field init fun(self: components.TrophyCard, opts: components.TrophyCard.Opts)
---@field _is_selected boolean
---@field _on_selection_change? fun(card: components.TrophyCard, selected: boolean)
---@field set_selected fun(self: components.TrophyCard, selected: boolean)
---@field is_selected fun(self: components.TrophyCard): boolean
---@field toggle_selection fun(self: components.TrophyCard)
local TrophyCard = class("components.TrophyCard", { super = BaseCard })

---@param opts components.TrophyCard.Opts
function TrophyCard:init(opts)
  validate(opts, {
    on_selection_change = "function?",
  })

  -- Initialize parent first
  BaseCard.init(self, opts)

  -- Then set up our custom TrophyCard state
  self._on_selection_change = opts.on_selection_change
  self._is_selected = false
  self.name = "TrophyCard"
end

--- Set the selection state of the card
---@param selected boolean
function TrophyCard:set_selected(selected)
  if self._is_selected == selected then
    return
  end

  self._is_selected = selected

  -- Update visual state - more prominent than pack cards since this is the main selection
  if selected then
    self:set_z(self:get_z() + 2)
    self:animate_style({
      scale = 1.15,
    }, { duration = 0.15, easing = "easeout" })
  else
    self:set_z(self:get_z() - 2)
    self:animate_style({
      scale = 1.0,
    }, { duration = 0.15, easing = "easeout" })
  end

  -- Notify parent component of selection change
  if self._on_selection_change then
    self._on_selection_change(self, selected)
  end
end

--- Check if the card is currently selected
---@return boolean
function TrophyCard:is_selected() return self._is_selected end

--- Toggle the selection state of the card
function TrophyCard:toggle_selection() self:set_selected(not self._is_selected) end

--- Override the click handler to delegate to parent
function TrophyCard:_click()
  -- Let the parent handle the selection logic
  if self._on_click then
    return self:_on_click()
  end

  return UIAction.HANDLED
end

--- Override render to add trophy-specific visual effects
function TrophyCard:_render()
  -- Call parent render first
  BaseCard._render(self)

  -- Add golden glow effect for trophy cards
  if self._is_selected then
    local x, y, width, height = self:get_geo()
    local glow_color = Colors.yellow:opacity(0.3)

    self:with_color(glow_color, function()
      love.graphics.setLineWidth(4)
      love.graphics.rectangle("line", x - 2, y - 2, width + 4, height + 4, 8, 8)
    end)
  end
end

function TrophyCard:__tostring()
  return string.format(
    "TrophyCard(%s, selected=%s)",
    self.card.name,
    self._is_selected
  )
end

return TrophyCard
