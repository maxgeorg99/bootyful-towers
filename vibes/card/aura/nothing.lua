local sprites = require("vibes.asset").sprites

---@class aura.Nothing : vibes.AuraCard
---@field new fun(): aura.Nothing
---@field init fun(self: aura.Reinforcements)
local CardEffectNothing = class("vibes.cards.Nothing", { super = AuraCard })
Encodable(CardEffectNothing, "vibes.cards.Nothing", "vibes.card.base-aura-card")

local name = "Nothing"
local description = "Do nothing"
-- local texture = sprites.card_vibe_reinforcements or sprites.card_aura_crit
local texture = sprites.card_aura_crit
local duration = EffectDuration.END_OF_MAP

---Creates a new Draw Cards effect card
function CardEffectNothing:init()
  AuraCard.init(self, {
    name = name,
    description = description,
    energy = 1,
    texture = texture,
    duration = duration,
    rarity = Rarity.COMMON,
    hooks = {},
  })
end

return CardEffectNothing
