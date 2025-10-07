local sprites = require("vibes.asset").sprites

local TowerCard = require "vibes.card.base-tower-card"

---@class (exact) vibes.TowerArcherCardOptions

---@class vibes.TowerLightningCard : vibes.TowerCard
---@field new fun(opts: vibes.TowerArcherCardOptions): vibes.TowerArcherCard
---@field init fun(self: vibes.TowerArcherCard, opts: vibes.TowerArcherCardOptions)
---@field tower vibes.LightningTower
local TowerLightningCard =
  class("vibes.tower-archer-card", { super = TowerCard })
Encodable(
  TowerLightningCard,
  "vibes.TowerLightningCard",
  "vibes.card.base-tower-card"
)

--- Creates a new Archer Tower card
---@return vibes.TowerArcherCard
function TowerLightningCard:init(opts)
  validate(opts, {})

  TowerCard.init(self, {
    name = "Lightning Tower",
    description = "LIGHTNING! KA CHOW! ",
    energy = 2,
    texture = sprites.card_tower_archer,
    rarity = Rarity.UNCOMMON,
    tower = require("vibes.tower.tower-lightning").new(),
  })
end

return TowerLightningCard
