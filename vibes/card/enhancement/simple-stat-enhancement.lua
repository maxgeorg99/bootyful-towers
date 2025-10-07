local M = {}

---@class enhancement.SimpleStat : vibes.EnhancementCard
---@field new fun(opts: enhancement.SimpleStat.Opts): enhancement.SimpleStat
---@field init fun(self: enhancement.SimpleStat, opts: enhancement.SimpleStat.Opts)
---@field operation tower.StatOperation
local SimpleStatEnhancement = class("enhancement.SimpleStat", {
  super = require "vibes.card.enhancement",
})
Encodable(
  SimpleStatEnhancement,
  "enhancement.SimpleStat",
  "vibes.card.enhancement"
)

---@class enhancement.SimpleStat.Opts : vibes.EnhancementCardOptions
---@field operation tower.StatOperation

--- Creates a new BaseEffectCard
---@param opts enhancement.SimpleStat.Opts
function SimpleStatEnhancement:init(opts)
  require("vibes.card.enhancement").init(self, opts)

  validate(opts, { operation = TowerStatOperation })
  self.operation = opts.operation
end

function SimpleStatEnhancement:is_active() return true end
function SimpleStatEnhancement:get_tower_operations(_tower, _dt)
  return { self.operation }
end

---@param operation StatOperation
M.new_enemy_target_card = function(operation)
  operation = operation
    or StatOperation.new { kind = StatOperationKind.ADD_BASE, value = 1 }

  return SimpleStatEnhancement.new {
    name = "Enemy Targets",
    description = "Gain +1 enemy target.",
    energy = 1,
    texture = Asset.sprites.card_effect_multi_shot,
    duration = EffectDuration.END_OF_MAP,
    rarity = Rarity.UNCOMMON,
    hooks = {},
    operation = TowerStatOperation.new {
      field = TowerStatField.ENEMY_TARGETS,
      operation = operation,
    },
  }
end

M.SimpleStatEnhancement = SimpleStatEnhancement

return M
