---@class vibes.LonelyTowerCard : vibes.EnhancementCard
---@field new fun(): vibes.LonelyTowerCard
---@field init fun(self: self)
---@field super vibes.EnhancementCard
local LonelyTowerCard =
  class("vibes.lonely-tower-card", { super = EnhancementCard })
Encodable(LonelyTowerCard, "vibes.LonelyTowerCard", "vibes.card.enhancement")

local name = "Lonely Tower"
local description =
  "Double your tower's damage if there is no tower in it's range"
local energy = 2
local texture = Asset.sprites.card_vibe_lonely_tower
local duration = EffectDuration.END_OF_MAP

function LonelyTowerCard:init()
  EnhancementCard.init(self, {
    name = name,
    description = description,
    energy = energy,
    texture = texture,
    duration = duration,
    hooks = {},
    rarity = Rarity.UNCOMMON,
  })
end

---@param tower vibes.Tower
---@return boolean
function LonelyTowerCard:is_active(tower)
  local tower_range = tower:get_range_in_distance()
  for _, other_tower in ipairs(State.towers) do
    if tower ~= other_tower then
      local dist = other_tower.position:distance_squared(tower.position)
      if dist <= tower_range then
        return false
      end
    end
  end

  return true
end

function LonelyTowerCard:get_tower_operations()
  return {
    TowerStatOperation.new {
      field = TowerStatField.DAMAGE,
      operation = StatOperation.new {
        kind = StatOperationKind.ADD_MULT,
        value = 2,
      },
    },
  }
end

return LonelyTowerCard
