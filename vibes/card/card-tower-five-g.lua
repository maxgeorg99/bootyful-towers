local sprites = require("vibes.asset").sprites

local TowerCard = require "vibes.card.base-tower-card"

---@class (exact) vibes.TowerFiveGCardOptions

---@class vibes.TowerFiveGCard : vibes.TowerCard
---@field new fun(opts: vibes.TowerFiveGCardOptions): vibes.TowerFiveGCard
---@field init fun(self: vibes.TowerFiveGCard, opts: vibes.TowerFiveGCardOptions)
---@field tower vibes.TowerFiveG
local TowerFiveGCard = class("vibes.tower-five-g-card", { super = TowerCard })
Encodable(TowerFiveGCard, "vibes.TowerFiveGCard", "vibes.card.base-tower-card")

--- Creates a new Five G Tower card
---@return vibes.TowerFiveGCard
function TowerFiveGCard:init(opts)
  validate(opts, {})

  TowerCard.init(self, {
    name = "5G Tower",
    description = "Fires arrows that turn enemies into rainbow flashing frogs. ",
    energy = 2,
    texture = sprites.orb_fire,
    rarity = Rarity.UNCOMMON,
    tower = require("vibes.tower.tower-five-g").new(),
  })
end

return TowerFiveGCard
