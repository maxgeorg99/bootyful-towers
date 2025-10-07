---@class vibes.EnhancementCard : vibes.EffectCard
---@field new fun(opts: vibes.EnhancementCardOptions): vibes.EnhancementCard
---@field init fun(self: self, opts: vibes.EnhancementCardOptions)
---@field super vibes.EffectCard
---@field is_active fun(self: self, tower: vibes.Tower): boolean
local EnhancementCard = class("vibes.enhancement-card", {
  super = EffectCard,
})

Encodable(
  EnhancementCard,
  "vibes.EnhancementCard",
  "vibes.card.base-effect-card",
  ---@param self vibes.EnhancementCard
  ---@return table<string, string>
  function(self)
    return {
      duration = tostring(self.duration),
    }
  end,
  ---@param self vibes.EnhancementCard
  ---@param data table<string, string>
  function(self, data) self.duration = EffectDuration[data.duration] end
)

---@class (exact) vibes.EnhancementCardOptions
---@field name string
---@field description string|function
---@field energy number
---@field texture vibes.Texture
---@field duration EffectDuration
---@field hooks vibes.effect.HookParams
---@field rarity Rarity

--- Creates a new BaseEffectCard
---@param opts vibes.EnhancementCardOptions
function EnhancementCard:init(opts)
  EffectCard.init(self, {
    kind = CardKind.ENHANCEMENT,
    name = opts.name,
    description = opts.description,
    energy = opts.energy,
    texture = opts.texture,
    duration = opts.duration,
    hooks = opts.hooks,
    rarity = opts.rarity,
    after_play_kind = CardAfterPlay.EXHAUST,
  })
end

function EnhancementCard:is_active(tower) return true end
function EnhancementCard:get_tower_operations(tower, dt) return {} end
function EnhancementCard:get_enemy_operations(enemy, dt) return {} end

---@param tower vibes.Tower
---@return tower.UpgradeOption?
function EnhancementCard:as_upgrade_option(tower) return nil end

---@param tower vibes.Tower
function EnhancementCard:can_apply_to_tower(tower)
  return tower.element_kind ~= ElementKind.ZOMBIE
end

return EnhancementCard
