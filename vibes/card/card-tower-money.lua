local sprites = require("vibes.asset").sprites

local TowerCard = require "vibes.card.base-tower-card"

---@class (exact) vibes.TowerMoneyCardOptions

---@class vibes.TowerMoneyCard : vibes.TowerCard
---@field new fun(opts: vibes.TowerMoneyCardOptions): vibes.TowerMoneyCard
---@field init fun(self: vibes.TowerMoneyCard, opts: vibes.TowerMoneyCardOptions)
---@field tower vibes.MoneyTower
local TowerMoneyCard = class("vibes.tower-money-card", { super = TowerCard })
Encodable(TowerMoneyCard, "vibes.TowerMoneyCard", "vibes.card.base-tower-card")

--- Creates a new Water Tower card
---@return vibes.TowerMoneyCard
function TowerMoneyCard:init(opts)
  validate(opts, {})

  TowerCard.init(self, {
    name = "Money Tower",
    description = "Gives 1 gold when an enemy dies. ",
    energy = 2,
    texture = sprites.water_tower, -- Using the tower sprite as card art for now
    rarity = Rarity.LEGENDARY,
    tower = require("vibes.tower.tower-money").new(),
  })
end

return TowerMoneyCard
