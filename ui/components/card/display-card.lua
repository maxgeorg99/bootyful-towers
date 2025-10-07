local CardElement = require "ui.components.card"

--- DisplayCard is a simple card component for displaying cards in collections
--- without interactive functionality like selection or dragging.
---
--- This is used in the card collection overlay to show all available cards.
---
---@class components.DisplayCard.Opts : components.Card.Opts
---
---@class (exact) components.DisplayCard : components.Card
---@field new fun(opts: components.DisplayCard.Opts): components.DisplayCard
---@field init fun(self: components.DisplayCard, opts: components.DisplayCard.Opts)
local DisplayCard = class("components.DisplayCard", { super = CardElement })

--- Create a new DisplayCard
---@param opts components.DisplayCard.Opts
function DisplayCard:init(opts)
  -- Initialize parent with non-interactive settings
  CardElement.init(self, opts)
  self.hide_level = true
  self.targets.scale = 1

  -- Make it non-interactive for display purposes
  self:set_interactable(false)
  self:set_draggable(false)
end

return DisplayCard
