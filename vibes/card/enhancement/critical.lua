local TowerUpgradeOption = require "vibes.tower.meta.tower-upgrade-option"
local TowerUtils = require "vibes.tower.tower-utils"

---@class enhancement.Critical : vibes.EnhancementCard
---@field new fun(opts: enhancement.Critical.Opts): enhancement.Critical
---@field init fun(self: enhancement.Critical, opts: enhancement.Critical.Opts)
local CriticalEnhancement =
  class("enhancement.Critical", { super = EnhancementCard })
Encodable(CriticalEnhancement, "enhancement.Critical", "vibes.card.enhancement")

---@class enhancement.Critical.Opts
---@field rarity Rarity

--- Creates a new CriticalEnhancement
---@param opts enhancement.Critical.Opts
function CriticalEnhancement:init(opts)
  validate(opts, { rarity = Rarity })

  EnhancementCard.init(self, {
    name = "Critical",
    description = function() return self:calculate_description() end,
    energy = 1,
    texture = Asset.sprites.card_aura_crit,
    duration = EffectDuration.END_OF_MAP,
    rarity = opts.rarity,
    hooks = {},
  })

  self.rarity = opts.rarity
end

function CriticalEnhancement:is_active() return true end

---@param tower vibes.Tower
function CriticalEnhancement:can_apply_to_tower(tower)
  return EnhancementCard.can_apply_to_tower(self, tower)
    and tower.element_kind == ElementKind.PHYSICAL
end

---@return tower.UpgradeOption
function CriticalEnhancement:as_upgrade_option(tower)
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
function CriticalEnhancement:get_tower_operations(tower, _dt)
  return TowerUtils.get_operation_by_kind(
    tower,
    self.rarity,
    TowerStatField.CRITICAL
  )
end

---@return string
function CriticalEnhancement:calculate_description()
  if self.rarity == Rarity.COMMON then
    return "Minor increase to tower critical chance."
  elseif self.rarity == Rarity.UNCOMMON then
    return "Moderate increase to tower critical chance."
  elseif self.rarity == Rarity.RARE then
    return "Major increase to tower critical chance."
  elseif self.rarity == Rarity.EPIC then
    return "Epic increase to tower critical chance."
  elseif self.rarity == Rarity.LEGENDARY then
    return "Legendary increase to tower critical chance."
  end
  error("Invalid rarity: " .. self.rarity)
end

return CriticalEnhancement
