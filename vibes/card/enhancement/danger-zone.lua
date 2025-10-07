local properties = {
  name = "Danger Zone",
  description = "Plus 30% damage, minus 50% range",
  energy = 2,
  texture = Asset.sprites.card_aura_danger_zone,
}

---@class vibes.DangerZoneEffectCard : vibes.EnhancementCard
local DangerZone = class("card.danger-zone", { super = EnhancementCard })
Encodable(DangerZone, "vibes.DangerZoneEffectCard", "vibes.card.enhancement")

function DangerZone:init()
  EnhancementCard.init(self, {
    name = properties.name,
    description = properties.description,
    energy = properties.energy,
    texture = properties.texture,
    duration = EffectDuration.END_OF_MAP,
    hooks = {},
    rarity = Rarity.RARE,
  })
end

function DangerZone:is_active() return true end

---@return tower.StatOperation[]
function DangerZone:get_tower_operations()
  return {
    TowerStatOperation.new {
      field = TowerStatField.DAMAGE,
      operation = StatOperation.new {
        kind = StatOperationKind.MUL_MULT,
        value = 1.3,
      },
    },
    TowerStatOperation.new {
      field = TowerStatField.RANGE,
      operation = StatOperation.new {
        kind = StatOperationKind.MUL_MULT,
        value = 0.5,
      },
    },
  }
end

return DangerZone
