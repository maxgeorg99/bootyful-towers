local TowerUpgradeOption = require "vibes.tower.meta.tower-upgrade-option"
local TowerUtils = require "vibes.tower.tower-utils"

---@class enhancement.AttackSpeed : vibes.EnhancementCard
---@field new fun(opts: enhancement.AttackSpeed.Opts): enhancement.AttackSpeed
---@field init fun(self: enhancement.AttackSpeed, opts: enhancement.AttackSpeed.Opts)
---@field rarity Rarity
local AttackSpeedEnhancement =
  class("enhancement.AttackSpeed", { super = EnhancementCard })
Encodable(
  AttackSpeedEnhancement,
  "enhancement.AttackSpeed",
  "vibes.card.enhancement"
)

---@class enhancement.AttackSpeed.Opts
---@field rarity Rarity

--- Creates a new AttackSpeedEnhancement
---@param opts enhancement.AttackSpeed.Opts
function AttackSpeedEnhancement:init(opts)
  validate(opts, { rarity = Rarity })

  EnhancementCard.init(self, {
    name = "Attack Speed",
    description = function() return self:calculate_description() end,
    energy = 1,
    texture = Asset.sprites.card_aura_speed,
    duration = EffectDuration.END_OF_MAP,
    rarity = opts.rarity,
    hooks = {},
  })

  self.rarity = opts.rarity
end

function AttackSpeedEnhancement:is_active() return true end

---@return tower.UpgradeOption
function AttackSpeedEnhancement:as_upgrade_option(tower)
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
function AttackSpeedEnhancement:get_tower_operations(tower, _dt)
  return TowerUtils.get_operation_by_kind(
    tower,
    self.rarity,
    TowerStatField.ATTACK_SPEED
  )
end

---@return string
function AttackSpeedEnhancement:calculate_description()
  if self.rarity == Rarity.COMMON then
    return "Minor increase to tower attack speed."
  elseif self.rarity == Rarity.UNCOMMON then
    return "Moderate increase to tower attack speed."
  elseif self.rarity == Rarity.RARE then
    return "Major increase to tower attack speed."
  elseif self.rarity == Rarity.EPIC then
    return "Epic increase to tower attack speed."
  elseif self.rarity == Rarity.LEGENDARY then
    return "Legendary increase to tower attack speed."
  end
  error("Invalid rarity: " .. self.rarity)
end

function AttackSpeedEnhancement:can_apply_to_tower(tower)
  return EnhancementCard.can_apply_to_tower(self, tower)
    or tower.element_kind == ElementKind.ZOMBIE
end

return AttackSpeedEnhancement
