local sprites = require("vibes.asset").sprites

local TowerCard = require "vibes.card.base-tower-card"

---@class vibes.TowerZombieHandsCard : vibes.TowerCard
---@field new fun(): vibes.TowerZombieHandsCard
---@field init fun(self: vibes.TowerZombieHandsCard)
---@field tower vibes.ZombieHandsTower
local TowerZombieHandsCard =
  class("vibes.tower-zombie-hands-card", { super = TowerCard })

Encodable(
  TowerZombieHandsCard,
  "vibes.TowerZombieHandsCard",
  "vibes.card.base-tower-card"
)

--- Creates a new Zombie Hands Tower card
function TowerZombieHandsCard:init(opts)
  validate(opts, {})

  TowerCard.init(self, {
    name = "Zombie Hands",
    description = "Undead hands emerge from the ground to grasp and immobilize enemies, holding them in place while dealing damage over time.",
    energy = 3,
    texture = sprites.dirt_mound,
    rarity = Rarity.UNCOMMON,
    tower = require("vibes.tower.tower-zombie-hands").new(),
  })
end

return TowerZombieHandsCard
