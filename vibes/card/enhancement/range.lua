local TowerUpgradeOption = require "vibes.tower.meta.tower-upgrade-option"
local TowerUtils = require "vibes.tower.tower-utils"

---@class enhancement.Range : vibes.EnhancementCard
---@field new fun(opts: enhancement.Range.Opts): enhancement.Range
---@field init fun(self: enhancement.Range, opts: enhancement.Range.Opts)
local RangeEnhancement = class("enhancement.Range", { super = EnhancementCard })
Encodable(RangeEnhancement, "enhancement.Range", "vibes.card.enhancement")

---@class enhancement.Range.Opts
---@field rarity Rarity

--- Creates a new Range enhancement card
---@param opts enhancement.Range.Opts
function RangeEnhancement:init(opts)
  validate(opts, { rarity = Rarity })

  EnhancementCard.init(self, {
    name = "Range",
    description = function() return self:calculate_description() end,
    energy = 1,
    texture = Asset.sprites.card_aura_range,
    duration = EffectDuration.END_OF_MAP,
    rarity = opts.rarity,
    hooks = {},
  })

  self.rarity = opts.rarity
end

function RangeEnhancement:is_active() return true end

---@return tower.UpgradeOption
function RangeEnhancement:as_upgrade_option(tower)
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
function RangeEnhancement:get_tower_operations(tower, _dt)
  return TowerUtils.get_operation_by_kind(
    tower,
    self.rarity,
    TowerStatField.RANGE
  )
end

---@return string
function RangeEnhancement:calculate_description()
  if self.rarity == Rarity.COMMON then
    return "Minor increase to tower range."
  elseif self.rarity == Rarity.UNCOMMON then
    return "Moderate increase to tower range."
  elseif self.rarity == Rarity.RARE then
    return "Major increase to tower range."
  elseif self.rarity == Rarity.EPIC then
    return "Epic increase to tower range."
  elseif self.rarity == Rarity.LEGENDARY then
    return "Legendary increase to tower range."
  end
  error("Invalid rarity: " .. self.rarity)
end

return RangeEnhancement
