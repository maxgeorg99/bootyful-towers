local sprites = require("vibes.asset").sprites

---@class aura.Nothing : vibes.AuraCard
---@field new fun(): aura.Nothing
---@field init fun(self: aura.Reinforcements)
local RustyScytheEffectCard = class("vibes.cards.Nothing", { super = AuraCard })
Encodable(
  RustyScytheEffectCard,
  "vibes.cards.Nothing",
  "vibes.card.base-aura-card"
)

local name = "Rusty Scythe"
local description = "Execute enemies below 30% health"
-- local texture = sprites.card_vibe_reinforcements or sprites.card_aura_crit
local texture = sprites.card_aura_crit
local duration = EffectDuration.END_OF_MAP

---Creates a new Draw Cards effect card
function RustyScytheEffectCard:init()
  AuraCard.init(self, {
    name = name,
    description = description,
    energy = 3,
    texture = texture,
    duration = duration,
    rarity = Rarity.UNCOMMON,
    hooks = {},
  })
end

--- Play the Rusty Scythe card effect
function RustyScytheEffectCard:play_effect_card()
  for _, enemy in ipairs(State.enemies) do
    print(enemy.health, enemy.max_health, enemy.health / enemy.max_health)
    if (enemy.health / enemy.max_health) < 0.3 then
      State:damage_enemy {
        enemy = enemy,
        damage = enemy.health,
        kind = DamageKind.PHYSICAL,
      }
    end
  end
end

return RustyScytheEffectCard
