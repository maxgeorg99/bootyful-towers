local BaseCard = require "ui.components.card"

---@class components.PackCard.Opts : components.Card.Opts
---@field on_selection_change? fun(card: components.PackCardElement, selected: boolean)

---@class (exact) components.PackCardElement : components.Card
---@field new fun(opts: components.PackCard.Opts): components.PackCardElement
---@field init fun(self: components.PackCardElement, opts: components.PackCard.Opts)
---@field _is_selected boolean
---@field _on_selection_change? fun(card: components.PackCardElement, selected: boolean)
---@field set_selected fun(self: components.PackCardElement, selected: boolean)
---@field is_selected fun(self: components.PackCardElement): boolean
---@field toggle_selection fun(self: components.PackCardElement)
local PackCard = class("components.PackCardElement", { super = BaseCard })

---@param opts components.PackCard.Opts
function PackCard:init(opts)
  validate(opts, {
    on_selection_change = "function?",
  })

  -- Initialize parent first
  BaseCard.init(self, opts)

  self.name = "PackCardElement"

  -- Then set up our custom PackCard state
  self._is_selected = false
  self._on_selection_change = opts.on_selection_change
end

--- Set the selection state of the card
---@param selected boolean
function PackCard:set_selected(selected)
  if self._is_selected == selected then
    return
  end

  self._is_selected = selected

  -- Update visual state
  if selected then
    self:set_z(self:get_z() + 1)
    self:animate_style({ scale = 1.1 }, { duration = 0.1 })
  else
    self:set_z(self:get_z() - 1)
    self:animate_style({ scale = 1 }, { duration = 0.1 })
  end

  -- Notify parent component of selection change
  if self._on_selection_change then
    self._on_selection_change(self, selected)
  end
end

--- Check if the card is currently selected
---@return boolean
function PackCard:is_selected() return self._is_selected end

--- Toggle the selection state of the card
function PackCard:toggle_selection() self:set_selected(not self._is_selected) end

--- Override the click handler to manage selection
function PackCard:_click()
  -- Handle our selection logic first
  self:toggle_selection()

  -- Then call the parent's click handler if it exists
  if self._on_click then
    return self:_on_click()
  end

  return UIAction.HANDLED
end

function PackCard:__tostring()
  return string.format(
    "PackCardElement(%s, selected=%s)",
    self.card.name,
    self._is_selected
  )
end

return PackCard
