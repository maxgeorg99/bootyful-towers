local sprites = require("vibes.asset").sprites

---@class aura.Reinforcements : vibes.AuraCard
---@field new fun(): aura.Reinforcements
---@field init fun(self: aura.Reinforcements)
local CardEffectReinforcements =
  class("vibes.cards.Reinforcements", { super = AuraCard })
Encodable(
  CardEffectReinforcements,
  "vibes.cards.Reinforcements",
  "vibes.card.base-aura-card"
)

local name = "Reinforcements"
local description = "Draw up to 2 cards from your deck"
-- local texture = sprites.card_vibe_reinforcements or sprites.card_aura_crit
local texture = sprites.card_aura_crit
local duration = EffectDuration.END_OF_MAP

---Creates a new Draw Cards effect card
function CardEffectReinforcements:init()
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

--- Play the Reinforcements card effect
function CardEffectReinforcements:play_effect_card() State.deck:draw_cards(2) end

return CardEffectReinforcements
