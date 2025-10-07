local TowerCard = require "vibes.card.base-tower-card"
local sprites = require("vibes.asset").sprites

---@class (exact) vibes.TowerCatapaultCard : vibes.TowerCard
---@field new fun(opts: vibes.TowerCatapaultCardOptions): vibes.TowerCatapaultCard
---@field init fun(self: vibes.TowerCatapaultCard, opts: vibes.TowerCatapaultCardOptions)
---@field tower vibes.CatapaultTower
---@field after_place vibes.Card
local TowerCatapaultCard =
  class("vibes.tower-catapault-card", { super = TowerCard })
Encodable(
  TowerCatapaultCard,
  "vibes.TowerCatapaultCard",
  "vibes.card.base-tower-card"
)

---@class (exact) vibes.TowerCatapaultCardOptions

--- Creates a new Catapault Tower card
---@param opts vibes.TowerCatapaultCardOptions
function TowerCatapaultCard:init(opts)
  opts = opts or {}

  local CatapaultTower = require "vibes.tower.tower-catapault"

  TowerCard.init(self, {
    name = "Catapault",
    description = "A slow shooting splash damage tower. ",
    energy = 2,
    texture = sprites.tower_catapault,
    rarity = Rarity.COMMON,
    tower = CatapaultTower.new(),
  })
end

return TowerCatapaultCard
