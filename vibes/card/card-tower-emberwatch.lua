local sprites = require("vibes.asset").sprites

local TowerCard = require "vibes.card.base-tower-card"

---@class (exact) vibes.TowerEmberWatchCardOptions

---@class vibes.TowerEmberWatchCard : vibes.TowerCard
---@field new fun(opts: vibes.TowerEmberWatchCardOptions): vibes.TowerEmberWatchCard
---@field init fun(self: vibes.TowerEmberWatchCard, opts: vibes.TowerEmberWatchCardOptions)
---@field tower vibes.ArcherTower
local TowerEmberWatchCard =
  class("vibes.tower-emberwatch-card", { super = TowerCard })
Encodable(
  TowerEmberWatchCard,
  "vibes.TowerEmberWatchCard",
  "vibes.card.base-tower-card"
)

--- Creates a new Archer Tower card
---@return vibes.TowerEmberWatchCard
function TowerEmberWatchCard:init(opts)
  validate(opts, {})

  TowerCard.init(self, {
    name = "Ember Watch",
    description = "An arrow tower that shoots fire. ",
    energy = 2,
    texture = sprites.orb_fire,
    rarity = Rarity.UNCOMMON,
    tower = require("vibes.tower.tower-emberwatch").new(),
  })
end

return TowerEmberWatchCard
