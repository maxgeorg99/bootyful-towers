local sprites = require("vibes.asset").sprites

local TowerCard = require "vibes.card.base-tower-card"

---@class (exact) vibes.TowerEarthCardOptions

---@class vibes.TowerEarthCard : vibes.TowerCard
---@field new fun(opts: vibes.TowerEarthCardOptions): vibes.TowerEarthCard
---@field init fun(self: vibes.TowerEarthCard, opts: vibes.TowerEarthCardOptions)
---@field tower vibes.EarthTower
local TowerEarthCard = class("vibes.tower-earth-card", { super = TowerCard })
Encodable(TowerEarthCard, "vibes.TowerEarthCard", "vibes.card.base-tower-card")

--- Creates a new Earth Tower card
---@return vibes.TowerEarthCard
function TowerEarthCard:init(opts)
  validate(opts, {})

  TowerCard.init(self, {
    name = "Earth Tower",
    description = "Protective stones that grant block when hitting enemies. ",
    energy = 2,
    texture = sprites.card_tower_tar, -- Using tar card sprite as placeholder
    rarity = Rarity.COMMON,
    tower = require("vibes.tower.tower-earth").new(),
  })
end

return TowerEarthCard
