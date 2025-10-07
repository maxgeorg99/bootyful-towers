local sprites = require("vibes.asset").sprites

---@class aura.GitStash : vibes.AuraCard
---@field new fun(): aura.GitStash
---@field init fun(self: aura.GitStash)
local GitStashCard = class("vibes.cards.GitStash", { super = AuraCard })
Encodable(GitStashCard, "vibes.cards.GitStash", "vibes.card.base-aura-card")

local name = "Git Stash"
local description = "Discard 2 random cards, then draw 2 cards"
local texture = sprites.card_vibe_git_stash
local duration = EffectDuration.END_OF_MAP

---Creates the Git Stash card which discards two random cards from hand and draws two.
function GitStashCard:init()
  AuraCard.init(self, {
    name = name,
    description = description,
    energy = 1,
    texture = texture,
    duration = duration,
    rarity = Rarity.UNCOMMON,
    hooks = {},
  })
end

--- Play the Git Stash card effect
function GitStashCard:play_effect_card()
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

  -- Then draw two cards
  State.deck:draw_cards(2)
end

return GitStashCard
