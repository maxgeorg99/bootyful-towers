local level_random =
  require("vibes.engine.random").new { name = "tower-level-up" }

---@class (exact) tower.ExperienceManager : vibes.Class
---@field new fun(opts: { tower: vibes.Tower }): tower.ExperienceManager
---@field init fun(self: tower.ExperienceManager, opts: { tower: vibes.Tower })
---@field tower vibes.Tower
---@field current_experience number Current experience in this level
---@field total_experience_earned number Total experience earned across all levels (never reset)
---@field experience_to_level number Experience needed for next level
local ExperienceManager = class "tower.ExperienceManager"

local experience_to_level = {
  [1] = 100,
  [2] = 400,
  [3] = 600,
  [4] = 950,
  [5] = 1600,
  [6] = 2400,
  [7] = 3200,
  [8] = 6400,
  [9] = 12800,
  [10] = 25600,
  [11] = 51200,
  [12] = 102400,
  [13] = 204800,
  [14] = 409600,
  [15] = 819200,
  [16] = 1638400,
  [17] = 3276800,
  [18] = 6553600,
  [19] = 13107200,
}

---@param opts { tower: vibes.Tower }
function ExperienceManager:init(opts)
  validate(opts, {
    tower = "table",
  })

  self.tower = opts.tower
  self.current_experience = 0
  self.total_experience_earned = 0
  self.experience_to_level = self.tower:initial_experience()
end

---@param amount number Amount of experience to grant
function ExperienceManager:gain_experience(amount)
  if amount <= 0 then
    return
  end

  -- Add to both current and total experience
  self.current_experience = self.current_experience + amount
  self.total_experience_earned = self.total_experience_earned + amount

  -- Check for level up
  if self.current_experience >= self.experience_to_level then
    self:level_up()
  end
end

---@param damage number Damage dealt to enemy
function ExperienceManager:apply_damage_experience(damage)
  local xp_amount = damage * Config.tower.experience_per_damage
  self:gain_experience(xp_amount)
end

---@param enemy vibes.Enemy Enemy that was killed
function ExperienceManager:apply_kill_experience(enemy)
  self:gain_experience(enemy.xp_reward)
end

---@param opts? { interactive: boolean }
function ExperienceManager:level_up(opts)
  opts = opts or {}
  opts.interactive = F.if_nil(opts.interactive, true)

  self.tower.level = self.tower.level + 1

  -- Subtract the XP requirement from current experience (preserve overflow)
  self.current_experience = self.current_experience - self.experience_to_level

  -- Scale up the XP requirement for next level
  -- TODO(balance): Not sure if this makes sense here.
  self.experience_to_level = experience_to_level[self.tower.level]
    or math.floor(
      self.experience_to_level * Config.tower.experience_level_multiplier
    )

  -- Increase card slots for levels below 10
  if self.tower.level < 10 then
    self.tower.card_slots = self.tower.card_slots + 1
  end

  if opts.interactive then
    local TowerLeveling = require "vibes.action.tower-leveling"
    ActionQueue:add(TowerLeveling.new { tower = self.tower })
  else
    local rewards = self.tower:get_levelup_reward()

    if rewards.kind == LevelUpRewardKind.EVOLVE_TOWER then
      local evolutions =
        assert(rewards:get_tower_evolution_options(), "No evolutions found")
      ---@cast evolutions tower.EvolutionOption[]
      local evolution = level_random:of_list(evolutions)
      evolution:apply(self.tower)
      if evolution.tower_name then
        self.tower.name = evolution.tower_name
      end
      return
    elseif rewards.kind == LevelUpRewardKind.UPGRADE_TOWER then
      local upgrades =
        assert(rewards:get_tower_upgrade_options(), "No upgrades found")
      ---@cast upgrades tower.UpgradeOption[]
      local upgrade = level_random:of_list(upgrades)
      upgrade:apply(self.tower)
      return
    end
  end
end

--- Get the tower's current level progress as a percentage
---@return number Percentage from 0 to 1
function ExperienceManager:get_level_progress()
  if self.experience_to_level <= 0 then
    return 1.0
  end
  return math.max(
    0.0,
    math.min(1.0, self.current_experience / self.experience_to_level)
  )
end

--- Check if the tower can level up
---@return boolean
function ExperienceManager:can_level_up()
  return self.current_experience >= self.experience_to_level
end

--- Get current experience for this level
---@return number
function ExperienceManager:get_current_experience()
  return self.current_experience
end

--- Get total experience earned across all levels
---@return number
function ExperienceManager:get_total_experience_earned()
  return self.total_experience_earned
end

--- Get experience needed for next level
---@return number
function ExperienceManager:get_experience_to_level()
  return self.experience_to_level
end

--- Reset experience state (for testing or special cases)
function ExperienceManager:reset()
  self.current_experience = 0
  self.total_experience_earned = 0
  self.experience_to_level = 600
end

return ExperienceManager
