local sprites = require("vibes.asset").sprites

---@class aura.Nothing : vibes.AuraCard
---@field new fun(): aura.Nothing
---@field init fun(self: aura.Reinforcements)
local CardEffectLittleApple = class("vibes.cards.Nothing", { super = AuraCard })
Encodable(
  CardEffectLittleApple,
  "vibes.cards.Nothing",
  "vibes.card.base-aura-card"
)

local name = "Little Apple"
local description = "+10 Health"
-- local texture = sprites.card_vibe_reinforcements or sprites.card_aura_crit
local texture = sprites.card_aura_health
local duration = EffectDuration.END_OF_MAP

---Creates a new Draw Cards effect card
function CardEffectLittleApple:init()
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

--- Play the Little Apple card effect
function CardEffectLittleApple:play_effect_card()
  State.player.health = State.player.health + 10
end

return CardEffectLittleApple
