---@class aura.LeakyStein : vibes.AuraCard
---@field new fun(): aura.LeakyStein
---@field init fun(self: aura.LeakyStein)
---@field super vibes.AuraCard
local LeakyStein = class("aura.LeakyStein", { super = AuraCard })
Encodable(LeakyStein, "aura.LeakyStein", "vibes.card.base-aura-card")

local name = "Leaky Stein"
local description = "Enemies pause for 0.3 seconds when turning at corners."
local energy = 2
local texture = Asset.sprites.card_vibe_leaky_stein
local duration = EffectDuration.END_OF_MAP

--- Creates a new Leaky Stein aura
function LeakyStein:init()
  AuraCard.init(self, {
    name = name,
    description = description,
    energy = energy,
    texture = texture,
    duration = duration,
    hooks = {},
    rarity = Rarity.RARE,
  })
end

--- Play the Leaky Stein card effect
function LeakyStein:play_effect_card()
  -- This aura works through the enemy stats system
  logger.info "Leaky Stein: Aura activated - enemies will pause when turning"
end

--- Whether this aura applies to the given enemy (applies to all enemies)
---@param _enemy vibes.Enemy
---@return boolean
function LeakyStein:is_active_on_enemy(_enemy)
  -- This aura applies to all enemies
  return true
end

--- Enemy operations granted by this aura (turn delay for all enemies)
---@param _enemy vibes.Enemy
---@return enemy.StatOperation[]
function LeakyStein:get_enemy_operations(_enemy)
  -- The turn delay is handled in the enemy update logic, not through stat operations
  return {}
end

--- Whether this aura applies to the given tower (not applicable for this aura)
---@param _tower vibes.Tower
---@return boolean
function LeakyStein:is_active_on_tower(_tower) return false end

--- Tower operations granted by this aura (none)
---@param _tower vibes.Tower
---@return tower.StatOperation[]
function LeakyStein:get_tower_operations(_tower) return {} end

return LeakyStein
