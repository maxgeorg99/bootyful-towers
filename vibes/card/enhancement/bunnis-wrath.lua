---@class enhancement.BunnisWrath : vibes.EnhancementCard
---@field new fun(): enhancement.BunnisWrath
---@field init fun(self: enhancement.BunnisWrath)
---@field super vibes.EnhancementCard
local BunnisWrath =
  class("enhancement.BunnisWrath", { super = EnhancementCard })
Encodable(BunnisWrath, "enhancement.BunnisWrath", "vibes.card.enhancement")

local name = "Bunni's Wrath"
local description = "+3 multiplier on critical hits"
local energy = 2
local texture = Asset.sprites.card_aura_bunnis_wrath
local duration = EffectDuration.END_OF_MAP

--- Creates a new Bunni's Wrath enhancement
function BunnisWrath:init()
  EnhancementCard.init(self, {
    name = name,
    description = description,
    energy = energy,
    texture = texture,
    duration = duration,
    rarity = Rarity.RARE,
    hooks = {},
  })
end

function BunnisWrath:is_active() return true end

---@param tower vibes.Tower
---@param _dt number
---@return tower.StatOperation[]
function BunnisWrath:get_tower_operations(tower, _dt)
  return {
    TowerStatOperation.new {
      field = TowerStatField.CRITICAL,
      operation = StatOperation.new {
        kind = StatOperationKind.ADD_MULT,
        value = 3.0, -- +3 critical multiplier
      },
    },
  }
end

---@param tower vibes.Tower
---@return boolean
function BunnisWrath:can_apply_to_tower(tower)
  -- Can apply to any tower since critical hits work for all damage types
  return true
end

return BunnisWrath
