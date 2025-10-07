local sprites = require("vibes.asset").sprites

---@class aura.Harpoon : vibes.AuraCard
---@field new fun(): aura.Harpoon
---@field init fun(self: aura.Harpoon)
local HarpoonAura = class("vibes.cards.Harpoon", { super = AuraCard })
Encodable(HarpoonAura, "vibes.cards.Harpoon", "vibes.card.base-aura-card")

HarpoonAura._properties = {
  name = "Harpoon",
  description = "Increase all PHYSICAL damage by 50%",
  energy = 2,
  texture = sprites.card_aura_damage, -- placeholder texture
  duration = EffectDuration.END_OF_MAP,
}

---Creates a new Harpoon aura card
function HarpoonAura:init()
  AuraCard.init(self, {
    name = HarpoonAura._properties.name,
    description = HarpoonAura._properties.description,
    energy = HarpoonAura._properties.energy,
    texture = HarpoonAura._properties.texture,
    duration = HarpoonAura._properties.duration,
    rarity = Rarity.LEGENDARY,
    hooks = {},
  })
end

--- Whether this aura applies to the given tower
---@param tower vibes.Tower
---@return boolean
function HarpoonAura:is_active_on_tower(tower)
  return tower.element_kind == ElementKind.PHYSICAL
end

--- Tower operations granted by this aura
---@param _tower vibes.Tower
---@return tower.StatOperation[]
function HarpoonAura:get_tower_operations(_tower)
  return {
    TowerStatOperation.mult_damage(1.5),
  }
end

return HarpoonAura
