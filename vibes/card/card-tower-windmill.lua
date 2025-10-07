local sprites = require("vibes.asset").sprites

local TowerCard = require "vibes.card.base-tower-card"

---@class (exact) vibes.TowerWindmillCardOptions

---@class vibes.TowerWindmillCard : vibes.TowerCard
---@field new fun(opts: vibes.TowerWindmillCardOptions): vibes.TowerWindmillCard
---@field init fun(self: vibes.TowerWindmillCard, opts: vibes.TowerWindmillCardOptions)
---@field tower vibes.TowerWindmill
local TowerWindmillCard =
  class("vibes.tower-windmill-card", { super = TowerCard })
Encodable(
  TowerWindmillCard,
  "vibes.TowerWindmillCard",
  "vibes.card.base-tower-card"
)

--- Creates a new Windmill Tower card
---@return vibes.TowerWindmillCard
function TowerWindmillCard:init(opts)
  validate(opts, {})

  TowerCard.init(self, {
    name = "Windmill",
    description = "All {enhance:enhancements} applied to this tower also apply to towers in its range.",
    energy = 2,
    texture = sprites.orb_fire,
    rarity = Rarity.UNCOMMON,
    tower = require("vibes.tower.tower-windmill").new(),
  })
end

return TowerWindmillCard
