---@class enhancement.LiveFastDieYoung : vibes.EnhancementCard
---@field new fun(opts: enhancement.LiveFastDieYoung.Opts): enhancement.LiveFastDieYoung
---@field init fun(self: enhancement.LiveFastDieYoung, opts: enhancement.LiveFastDieYoung.Opts)
---@field rarity Rarity
local LiveFastDieYoung =
  class("enhancement.LiveFastDieYoung", { super = EnhancementCard })

---@class enhancement.LiveFastDieYoung.Opts
---@field rarity Rarity

--- Creates a new LiveFastDieYoung enhancement
---@param opts enhancement.LiveFastDieYoung.Opts
function LiveFastDieYoung:init(opts)
  opts = opts or {}
  opts.rarity = opts.rarity or Rarity.COMMON

  EnhancementCard.init(self, {
    name = "Live Fast Die Young",
    description = function() return self:calculate_description() end,
    energy = 2,
    texture = Asset.sprites.card_aura_live_fast_die_young,
    duration = EffectDuration.END_OF_MAP,
    rarity = opts.rarity,
    hooks = {
      -- No hooks needed - damage bonus is applied directly in GameState:damage_enemy
    },
  })

  self.rarity = opts.rarity
end

function LiveFastDieYoung:is_active() return true end

function LiveFastDieYoung:get_tower_operations(_tower, _dt)
  -- This enhancement doesn't provide static stat operations
  -- Instead, it dynamically modifies damage based on enemy speed through tower behavior
  return {}
end

--- Calculate the speed multiplier based on enemy speed
---@param enemy_speed number
---@return number
function LiveFastDieYoung:_get_speed_multiplier(enemy_speed)
  -- Base multiplier values by rarity
  local base_multipliers = {
    [Rarity.COMMON] = 0.1, -- 10% per speed unit
    [Rarity.UNCOMMON] = 0.15, -- 15% per speed unit
    [Rarity.RARE] = 0.2, -- 20% per speed unit
    [Rarity.EPIC] = 0.25, -- 25% per speed unit
    [Rarity.LEGENDARY] = 0.3, -- 30% per speed unit
  }

  local multiplier_per_speed = base_multipliers[self.rarity] or 0.1

  -- Calculate the final multiplier: 1 + (speed * multiplier_per_speed)
  -- This means faster enemies take more damage
  return 1 + (enemy_speed * multiplier_per_speed)
end

--- Calculate description based on the rarity
---@return string
function LiveFastDieYoung:calculate_description()
  if not self.rarity then
    return "Deal more damage to faster enemies."
  end

  local multiplier_per_speed = ({
    [Rarity.COMMON] = 10,
    [Rarity.UNCOMMON] = 15,
    [Rarity.RARE] = 20,
    [Rarity.EPIC] = 25,
    [Rarity.LEGENDARY] = 30,
  })[self.rarity] or 10

  return string.format(
    "Deal +{damage:%d%%} damage per enemy speed unit.\nFaster enemies take more damage.",
    multiplier_per_speed
  )
end

return LiveFastDieYoung
