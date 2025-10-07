local sprites = require("vibes.asset").sprites

---@class aura.GoFish : vibes.AuraCard
---@field new fun(): aura.GoFish
---@field init fun(self: aura.GoFish)
local GoFishCard = class("vibes.cards.GoFish", { super = AuraCard })
Encodable(GoFishCard, "vibes.cards.GoFish", "vibes.card.base-aura-card")

local name = "Go Fish"
local description = "Discard 2 random cards from your hand"
local texture = sprites.card_vibe_go_fish
local duration = EffectDuration.END_OF_MAP

---Creates the Go Fish card which discards two random cards from hand.
function GoFishCard:init()
  AuraCard.init(self, {
    name = name,
    description = description,
    energy = 0,
    texture = texture,
    duration = duration,
    rarity = Rarity.COMMON,
    hooks = {},
  })
end

--- Play the Go Fish card effect
function GoFishCard:play_effect_card()
  local hand = State.deck.hand

  -- Discard up to two random cards currently in hand (if available)
  local to_discard = math.min(2, #hand)
  for _ = 1, to_discard do
    if #hand == 0 then
      break
    end
    local idx = math.random(1, #hand)
    local card = hand[idx]
    State.deck:discard_card(card)
  end
end

return GoFishCard
