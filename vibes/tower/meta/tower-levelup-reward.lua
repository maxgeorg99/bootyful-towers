local TowerEvolutionOption = require "vibes.tower.meta.tower-evolution-option"
local TowerUpgradeOption = require "vibes.tower.meta.tower-upgrade-option"

---@class tower.LevelUpReward : vibes.Class
---@field new fun(opts: tower.LevelUpReward.Opts): tower.LevelUpReward
---@field init fun(self: tower.LevelUpReward, opts: tower.LevelUpReward.Opts)
---@field kind LevelUpRewardKind
---@field reward tower.UpgradeOption[]|tower.EvolutionOption[]
local TowerLevelUpReward = class "vibes.TowerLevelUpReward"

---@class tower.LevelUpReward.Opts
---@field kind LevelUpRewardKind
---@field reward tower.UpgradeOption[]|tower.EvolutionOption[]

function TowerLevelUpReward:init(opts)
  validate(opts, {
    kind = LevelUpRewardKind,
  })

  if opts.kind == LevelUpRewardKind.UPGRADE_TOWER then
    ---@type tower.UpgradeOption[]
    local reward = opts.reward

    assert(reward and #reward > 0, "there must be rewards")
    for _, reward in ipairs(reward) do
      assert(
        reward.operations and #reward.operations > 0,
        "reward must have at least one operation"
      )
    end

    validate(reward, {
      List { TowerUpgradeOption },
    })
  elseif opts.kind == LevelUpRewardKind.EVOLVE_TOWER then
    validate(opts.reward, {
      List { TowerEvolutionOption },
    })
  end

  self.kind = opts.kind
  self.reward = opts.reward
end

---@return tower.UpgradeOption[]?
function TowerLevelUpReward:get_tower_upgrade_options()
  assert(
    self.kind == LevelUpRewardKind.UPGRADE_TOWER,
    "upgrade reward must be a tower upgrade"
  )
  return self.reward
end

---@return tower.EvolutionOption[]?
function TowerLevelUpReward:get_tower_evolution_options()
  assert(
    self.kind == LevelUpRewardKind.EVOLVE_TOWER,
    "evolution reward must be a tower evolution"
  )
  return self.reward
end

return TowerLevelUpReward
