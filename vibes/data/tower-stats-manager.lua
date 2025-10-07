---@class (exact) tower.StatsManager
---@field new fun(opts: tower.StatsManager.Opts): tower.StatsManager
---@field init fun(self: tower.StatsManager, opts: tower.StatsManager.Opts)
---@field private tower vibes.Tower
---@field result tower.Stats Resulting stats
local TowerStatsManager = class "vibes.tower-stats-manager"

---@class tower.StatsManager.Opts
---@field tower vibes.Tower

---@param opts tower.StatsManager.Opts
function TowerStatsManager:init(opts)
  self.tower = opts.tower
  self.result = opts.tower.stats_base:clone()
end

--- Hook for calling update on the tower, possibly could be called "compute", that's what I had before
function TowerStatsManager:update(_dt)
  self.result = self.tower.stats_base:clone()

  ---@type tower.StatOperation[]
  local operations = {}

  State.gear_manager:for_gear_in_active_gear(function(gear)
    if gear:is_active_on_tower(self.tower) then
      table.list_extend(operations, gear:get_tower_operations(self.tower))
    end
  end)

  for _, aura in ipairs(State.auras) do
    if aura:is_active_on_tower(self.tower) then
      table.list_extend(operations, aura:get_tower_operations(self.tower))
    end
  end

  -- for _, enhancement in ipairs(State.levels:get_current_level().enhancements) do
  --   if enhancement:is_active(self.tower) then
  --     table.list_extend(operations, enhancement:get_tower_operations(self.tower, _dt))
  --   end
  -- end

  -- TODO(perf): Nice if we didn't search all the towers
  for _, tower in ipairs(State.towers) do
    if tower ~= self.tower then
      if tower:is_supporting_tower(self.tower) then
        table.list_extend(
          operations,
          tower:get_support_tower_operations(self.tower)
        )
      end
    end
  end

  for _, enhancement in ipairs(self.tower.enhancements) do
    if enhancement:is_active(self.tower) then
      table.list_extend(
        operations,
        enhancement:get_tower_operations(self.tower, _dt)
      )
    end
  end

  for _, tower_operation in ipairs(operations) do
    tower_operation:apply_to_tower_stats(self.result)
  end
end

return TowerStatsManager
