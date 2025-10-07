local sprites = require("vibes.asset").sprites

local TowerCard = require "vibes.card.base-tower-card"

---@class (exact) vibes.TowerWaterCardOptions

---@class vibes.TowerWaterCard : vibes.TowerCard
---@field new fun(opts: vibes.TowerWaterCardOptions): vibes.TowerWaterCard
---@field init fun(self: vibes.TowerWaterCard, opts: vibes.TowerWaterCardOptions)
---@field tower vibes.WaterTower
local TowerWaterCard = class("vibes.tower-water-card", { super = TowerCard })
Encodable(TowerWaterCard, "vibes.TowerWaterCard", "vibes.card.base-tower-card")

--- Creates a new Water Tower card
---@return vibes.TowerWaterCard
function TowerWaterCard:init(opts)
  validate(opts, {})

  TowerCard.init(self, {
    name = "Water Tower",
    description = "Shoots water that ignores shields and deals direct damage to health. ",
    energy = 2,
    texture = sprites.water_tower, -- Using the tower sprite as card art for now
    rarity = Rarity.COMMON,
    tower = require("vibes.tower.tower-water").new(),
  })
end

return TowerWaterCard
