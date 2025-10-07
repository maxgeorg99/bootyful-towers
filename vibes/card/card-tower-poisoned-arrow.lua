local sprites = require("vibes.asset").sprites

local TowerCard = require "vibes.card.base-tower-card"

---@class (exact) vibes.TowerPoisonedArrowCardOptions

---@class vibes.TowerPoisonedArrowCard : vibes.TowerCard
---@field new fun(opts: vibes.TowerPoisonedArrowCardOptions): vibes.TowerPoisonedArrowCard
---@field init fun(self: vibes.TowerPoisonedArrowCard, opts: vibes.TowerPoisonedArrowCardOptions)
---@field tower vibes.PoisonedArrowTower
local TowerPoisonedArrowCard =
  class("vibes.tower-poisoned-arrow-card", { super = TowerCard })
Encodable(
  TowerPoisonedArrowCard,
  "vibes.TowerPoisonedArrowCard",
  "vibes.card.base-tower-card"
)

--- Creates a new Archer Tower card
---@return vibes.TowerPoisonedArrowCard
function TowerPoisonedArrowCard:init(opts)
  validate(opts, {})

  TowerCard.init(self, {
    name = "Poisoned Arrow",
    description = "The Poisoned Arrow Tower. ",
    energy = 2,
    texture = sprites.tower_poisoned_arrow,
    rarity = Rarity.RARE,
    tower = require("vibes.tower.tower-poisoned-arrow").new(),
  })
end

return TowerPoisonedArrowCard
