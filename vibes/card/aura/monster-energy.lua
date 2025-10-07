local sprites = require("vibes.asset").sprites

---@class aura.Nothing : vibes.AuraCard
---@field new fun(): aura.Nothing
---@field init fun(self: aura.Reinforcements)
local MonsterEnergyEffectCard =
  class("vibes.cards.Nothing", { super = AuraCard })
Encodable(
  MonsterEnergyEffectCard,
  "vibes.cards.Nothing",
  "vibes.card.base-aura-card"
)

local name = "Monster Energy"
local description = "+3 Energy. Lose 6 Health."
-- local texture = sprites.card_vibe_reinforcements or sprites.card_aura_crit
local texture = sprites.card_aura_crit
local duration = EffectDuration.END_OF_MAP

---Creates a new Draw Cards effect card
function MonsterEnergyEffectCard:init()
  AuraCard.init(self, {
    name = name,
    description = description,
    energy = 0,
    texture = texture,
    duration = duration,
    rarity = Rarity.RARE,
    hooks = {},
  })
end

--- Play the Monster Energy card effect
function MonsterEnergyEffectCard:play_effect_card()
  State.player:gain_energy(3)
  State.player:damage_health(6)
end

return MonsterEnergyEffectCard
