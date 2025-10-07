local sprites = require("vibes.asset").sprites

local TowerCard = require "vibes.card.base-tower-card"

---@class (exact) vibes.TowerArcherCardOptions

---@class vibes.TowerArcherCard : vibes.TowerCard
---@field new fun(opts: vibes.TowerArcherCardOptions): vibes.TowerArcherCard
---@field init fun(self: vibes.TowerArcherCard, opts: vibes.TowerArcherCardOptions)
---@field tower vibes.ArcherTower
local TowerArcherCard = class("vibes.tower-archer-card", { super = TowerCard })
Encodable(
  TowerArcherCard,
  "vibes.TowerArcherCard",
  "vibes.card.base-tower-card"
)

--- Creates a new Archer Tower card
---@return vibes.TowerArcherCard
function TowerArcherCard:init(opts)
  validate(opts, {})

  TowerCard.init(self, {
    name = "Archer Tower",
    description = "A Basic Arrow Tower. ",
    energy = 2,
    texture = sprites.card_tower_archer,
    rarity = Rarity.COMMON,
    tower = require("vibes.tower.tower-archer").new(),
  })
end

return TowerArcherCard
