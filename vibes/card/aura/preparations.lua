local sprites = require("vibes.asset").sprites

---@class vibes.cards.Preparations : vibes.AuraCard
---@field new fun(): vibes.cards.Preparations
---@field init fun(self: vibes.cards.Preparations)
local CardEffectPreparations =
  class("vibes.cards.Preparations", { super = AuraCard })
Encodable(
  CardEffectPreparations,
  "vibes.cards.Preparations",
  "vibes.card.base-aura-card"
)

local name = "Preparations"
local description = "Reduces the health of enemies by {20%} at spawn."
local texture = sprites.card_aura_overdrive
local duration = EffectDuration.END_OF_MAP

---Creates a new Draw Cards effect card
function CardEffectPreparations:init()
  AuraCard.init(self, {
    name = name,
    description = description,
    energy = 1,
    texture = texture,
    duration = duration,
    rarity = Rarity.EPIC,
    hooks = {
      after_enemy_spawn = function(self, opts)
        opts.enemy.health = opts.enemy.health * 0.8 ^ self.level
      end,
    },
  })
end

--- Encode this card for saving.
--- @return table<string, string>
function CardEffectPreparations:encode()
  local data = AuraCard.encode(self)
  data["_type"] = "vibes.PreparationsCard"
  return data
end

--- Update a card from JSON (used for re-creating saved cards)
--- @param data table<string, string>
--- @return vibes.cards.Preparations
function CardEffectPreparations:decode(data)
  AuraCard.decode(self, data)
  return self
end

return CardEffectPreparations
