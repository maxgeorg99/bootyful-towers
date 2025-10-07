--- Critical damage calculation system
--- Handles cascading critical hits where crits over 100% can trigger additional crits
---@class vibes.CriticalDamage
local CriticalDamage = {}

local Random = require "vibes.engine.random"

--- Random generator for critical damage calculations
local critical_random = Random.new {
  name = "CriticalDamage",
}

--- Calculate critical damage with cascading crits
--- If critical chance exceeds 100%, it can trigger additional critical hits
---@param base_damage number The base damage to potentially modify
---@param critical_chance number Critical chance as a decimal (0.05 = 5%, 1.5 = 150%)
---@return { damage: number, crits_triggered: number } Final damage and number of crits
function CriticalDamage.calculate_critical_damage(base_damage, critical_chance)
  local final_damage = base_damage
  local crits_triggered = 0
  local remaining_chance = critical_chance

  -- Keep rolling for crits while we have a chance remaining
  while remaining_chance > 0 do
    local roll = critical_random:random() -- 0 to 1

    -- If our remaining chance is >= 1, we're guaranteed a crit
    -- If it's < 1, we need to roll under the remaining chance
    if remaining_chance >= 1.0 or roll <= remaining_chance then
      -- Critical hit! Double the damage
      final_damage = final_damage * 2
      crits_triggered = crits_triggered + 1

      -- Reduce remaining chance by 100% (1.0)
      remaining_chance = remaining_chance - 1.0
    else
      -- No crit, stop rolling
      break
    end

    -- Safety valve - prevent infinite loops (should never happen, but Lua...)
    if crits_triggered >= 10 then
      logger.warn "CriticalDamage: Hit maximum crit limit of 10, stopping calculation"
      break
    end
  end

  return {
    damage = final_damage,
    crits_triggered = crits_triggered,
  }
end

return CriticalDamage
