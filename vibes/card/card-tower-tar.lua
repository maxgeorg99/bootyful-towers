local sprites = require("vibes.asset").sprites
local TowerCard = require "vibes.card.base-tower-card"

---@class (exact) vibes.TarTowerCard : vibes.TowerCard
---@field new fun(): vibes.TarTowerCard
---@field init fun(self: vibes.TarTowerCard)
---@field super vibes.TowerCard
---@field tower vibes.TarTower
local TarTowerCard = class("vibes.tar-tower-card", { super = TowerCard })
Encodable(TarTowerCard, "vibes.TarTowerCard", "vibes.card.base-tower-card")

--- Creates a new Tar Tower card
function TarTowerCard:init()
  TowerCard.init(self, {
    name = "Tar Tower",
    description = "Slow your enemies down and make them cry. ",
    energy = 2,
    texture = sprites.card_tower_tar,
    tower = require("vibes.tower.tower-tar").new(),
    rarity = Rarity.UNCOMMON,
  })
end

return TarTowerCard
