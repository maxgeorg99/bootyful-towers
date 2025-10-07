---@class enhancement.Dam : vibes.EnhancementCard
---@field new fun(opts: enhancement.Dam.Opts): enhancement.Dam
---@field init fun(self: enhancement.Dam, opts: enhancement.Dam.Opts)
---@field is_played boolean
---@field accumulated_multiplier number
local Dam = class("enhancement.Dam", { super = EnhancementCard })

---@class enhancement.Dam.Opts
---@field rarity Rarity

--- Creates a new DamageEnhancement
---@param opts enhancement.Dam.Opts
function Dam:init(opts)
  validate(opts, { rarity = Rarity })

  -- TODO:
  -- legendary gives zero energy

  EnhancementCard.init(self, {
    name = "Dam",
    description = function()
      return string.format(
        "{damage:%sx mult}.\n+{damage:%sx} per draw.\nReset on play.",
        self.accumulated_multiplier,
        self:_get_additional_multiplier()
      )
    end,
    energy = 1,
    texture = Asset.sprites.card_enhancement_dam,
    duration = EffectDuration.END_OF_MAP,
    rarity = opts.rarity,
    hooks = {
      on_card_drawn = function(self_card)
        self.accumulated_multiplier = self.accumulated_multiplier
          + self:_get_additional_multiplier()
      end,
      after_level_end = function()
        if self.is_played then
          self.accumulated_multiplier = self:_get_initial_multiplier()
        end
      end,
    },
  })

  self.rarity = opts.rarity
  self.accumulated_multiplier = self:_get_initial_multiplier()
end

function Dam:_get_initial_multiplier()
  if self.rarity == Rarity.COMMON then
    return -0.2
  elseif self.rarity == Rarity.UNCOMMON then
    return -0.1
  elseif self.rarity == Rarity.RARE then
    return 0
  elseif self.rarity == Rarity.EPIC then
    return 0.1
  elseif self.rarity == Rarity.LEGENDARY then
    return 0.2
  end

  return 0
end

function Dam:_get_additional_multiplier()
  if self.rarity == Rarity.COMMON then
    return 0.1
  elseif self.rarity == Rarity.UNCOMMON then
    return 0.2
  elseif self.rarity == Rarity.RARE then
    return 0.3
  elseif self.rarity == Rarity.EPIC then
    return 0.4
  elseif self.rarity == Rarity.LEGENDARY then
    return 0.5
  end
end

function Dam:is_active() return true end

function Dam:get_tower_operations(_tower, _dt)
  return {
    TowerStatOperation.new {
      field = TowerStatField.DAMAGE,
      operation = StatOperation.add_mult(self.accumulated_multiplier),
    },
  }
end

return Dam
