local TowerUpgradeOption = require "vibes.tower.meta.tower-upgrade-option"
local TowerUtils = require "vibes.tower.tower-utils"

---@class enhancement.Damage : vibes.EnhancementCard
---@field new fun(opts: enhancement.Damage.Opts): enhancement.Damage
---@field init fun(self: enhancement.Damage, opts: enhancement.Damage.Opts)
local DamageEnhancement =
  class("enhancement.Damage", { super = EnhancementCard })
Encodable(DamageEnhancement, "enhancement.Damage", "vibes.card.enhancement")

---@class enhancement.Damage.Opts
---@field rarity Rarity

--- Creates a new DamageEnhancement
---@param opts enhancement.Damage.Opts
function DamageEnhancement:init(opts)
  validate(opts, { rarity = Rarity })

  EnhancementCard.init(self, {
    name = "Damage",
    description = function() return self:calculate_description() end,
    energy = 1,
    texture = Asset.sprites.card_aura_damage,
    duration = EffectDuration.END_OF_MAP,
    rarity = opts.rarity,
    hooks = {},
  })

  self.rarity = opts.rarity
end

function DamageEnhancement:is_active() return true end

---@return tower.UpgradeOption
function DamageEnhancement:as_upgrade_option(tower)
  return TowerUpgradeOption.new {
    name = self.name,
    rarity = self.rarity,
    operations = self:get_tower_operations(tower, 0),
    description = self:calculate_description(),
  }
end

---@param tower vibes.Tower
---@param _dt number
---@return tower.StatOperation[]
function DamageEnhancement:get_tower_operations(tower, _dt)
  return TowerUtils.get_operation_by_kind(
    tower,
    self.rarity,
    TowerStatField.DAMAGE
  )
end

---@return string
function DamageEnhancement:calculate_description()
  if self.rarity == Rarity.COMMON then
    return "Minor increase to tower damage."
  elseif self.rarity == Rarity.UNCOMMON then
    return "Moderate increase to tower damage."
  elseif self.rarity == Rarity.RARE then
    return "Major increase to tower damage."
  elseif self.rarity == Rarity.EPIC then
    return "Epic increase to tower damage."
  elseif self.rarity == Rarity.LEGENDARY then
    return "Legendary increase to tower damage."
  end
  assert(false, "Invalid rarity: " .. self.rarity)
  return "unknown"
end

return DamageEnhancement
