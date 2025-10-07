local sprites = require("vibes.asset").sprites

---@class aura.Nothing : vibes.AuraCard
---@field new fun(): aura.Nothing
---@field init fun(self: aura.Reinforcements)
local CardEffectGoldenSack = class("vibes.cards.Nothing", { super = AuraCard })
Encodable(
  CardEffectGoldenSack,
  "vibes.cards.Nothing",
  "vibes.card.base-aura-card"
)

local name = "Golden Sack"
local description = "+5 Gold"
-- local texture = sprites.card_vibe_reinforcements or sprites.card_aura_crit
local texture = sprites.card_aura_crit
local duration = EffectDuration.END_OF_MAP

---Creates a new Draw Cards effect card
function CardEffectGoldenSack:init()
  AuraCard.init(self, {
    name = name,
    description = description,
    energy = 1,
    texture = texture,
    duration = duration,
    rarity = Rarity.RARE,
    hooks = {},
  })
end

--- Play the Golden Sack card effect
function CardEffectGoldenSack:play_effect_card() State.player:gain_gold(5) end

return CardEffectGoldenSack
