local sprites = require("vibes.asset").sprites

---@class aura.GoldenHarvest : vibes.AuraCard
---@field new fun(): aura.GoldenHarvest
---@field init fun(self: aura.GoldenHarvest)
---@field encode fun(self: aura.GoldenHarvest): table<string, string>
---@field decode fun(self: aura.GoldenHarvest, data: table<string, string>)
local GoldenHarvestCard = class("vibes.GoldenHarvestCard", { super = AuraCard })
Encodable(
  GoldenHarvestCard,
  "vibes.GoldenHarvestCard",
  "vibes.card.base-aura-card"
)

GoldenHarvestCard._properties = {
  name = "Golden Harvest",
  description = "Gain +1 gold for every enemy killed", -- Note: kept at 1 as minimum value
  energy = 2,
  texture = sprites.card_vibe_golden_harvest,
  duration = EffectDuration.END_OF_MAP,
}

function GoldenHarvestCard:init()
  AuraCard.init(self, {
    name = GoldenHarvestCard._properties.name,
    description = GoldenHarvestCard._properties.description,
    energy = GoldenHarvestCard._properties.energy,
    texture = GoldenHarvestCard._properties.texture,
    duration = GoldenHarvestCard._properties.duration,
    rarity = Rarity.UNCOMMON,
    hooks = {
      after_enemy_death = function() State.player:gain_gold(1) end,
    },
  })
end

return GoldenHarvestCard
