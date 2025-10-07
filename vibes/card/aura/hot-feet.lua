---@class aura.HotFeet : vibes.AuraCard
---@field new fun(): aura.HotFeet
---@field init fun(self: aura.HotFeet)
---@field super vibes.AuraCard
local HotFeet = class("aura.HotFeet", { super = AuraCard })

local name = "Hot Feet"
local description = "Enemies with burning status effect move 48% faster."
local energy = 1
local texture = Asset.sprites.card_aura_hot_feet
local duration = EffectDuration.END_OF_MAP

--- Creates a new HotFeet aura
function HotFeet:init()
  AuraCard.init(self, {
    name = name,
    description = description,
    energy = energy,
    texture = texture,
    duration = duration,
    hooks = {},
    rarity = Rarity.UNCOMMON,
  })
end

--- Play the Hot Feet card effect
function HotFeet:play_effect_card()
  -- This aura works through the enemy stats system
  logger.info "Hot Feet: Aura activated - burning enemies will move faster"
end

--- Whether this aura applies to the given enemy (applies to burning enemies)
---@param enemy vibes.Enemy
---@return boolean
function HotFeet:is_active_on_enemy(enemy)
  -- Check if the enemy has burning status (fire stacks > 0)
  return enemy.fire_stacks > 0
end

--- Enemy operations granted by this aura (speed boost for burning enemies)
---@param enemy vibes.Enemy
---@return enemy.StatOperation[]
function HotFeet:get_enemy_operations(enemy)
  -- Only apply speed boost if enemy is burning
  if not self:is_active_on_enemy(enemy) then
    return {}
  end

  return {
    EnemyStatOperation.new {
      field = EnemyStatField.SPEED,
      operation = StatOperation.new {
        kind = StatOperationKind.ADD_BASE,
        value = enemy.fire_stacks * 12,
      },
    },
  }
end

--- Whether this aura applies to the given tower (not applicable for this aura)
---@param _tower vibes.Tower
---@return boolean
function HotFeet:is_active_on_tower(_tower) return false end

--- Tower operations granted by this aura (none)
---@param _tower vibes.Tower
---@return tower.StatOperation[]
function HotFeet:get_tower_operations(_tower) return {} end

return HotFeet
