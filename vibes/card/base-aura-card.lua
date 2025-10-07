local BaseEffectCard = require "vibes.card.base-effect-card"

---@class vibes.AuraCard : vibes.EffectCard, Encodable
---@field new fun(opts: vibes.AuraCardOptions): vibes.AuraCard
---@field init fun(self: self, opts: vibes.AuraCardOptions)
local AuraCard = class("vibes.aura-card", { super = BaseEffectCard })
Encodable(AuraCard, "vibes.AuraCard", "vibes.card.base-effect-card")

---@class (exact) vibes.AuraCardOptions
---@field name string
---@field description string
---@field energy number
---@field texture vibes.Texture
---@field duration EffectDuration
---@field hooks vibes.effect.HookParams
---@field rarity Rarity

--- Creates a new AuraCard
---@param opts vibes.AuraCardOptions
function AuraCard:init(opts)
  BaseEffectCard.init(self, {
    kind = CardKind.AURA,
    name = opts.name,
    description = opts.description,
    energy = opts.energy,
    texture = opts.texture,
    duration = opts.duration,
    hooks = opts.hooks,
    rarity = opts.rarity,
  })
end

---@param tower vibes.Tower
---@return boolean
function AuraCard:is_active_on_tower(tower) return false end

---@param tower vibes.Tower
---@return tower.StatOperation[]
function AuraCard:get_tower_operations(tower) return {} end

---@param enemy vibes.Enemy
---@return boolean
function AuraCard:is_active_on_enemy(enemy) return false end

---@param enemy vibes.Enemy
---@return enemy.StatOperation[]
function AuraCard:get_enemy_operations(enemy) return {} end

return AuraCard
