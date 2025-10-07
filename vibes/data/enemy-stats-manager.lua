---@class (exact) enemy.StatsManager
---@field new fun(opts: enemy.StatsManager.Opts): enemy.StatsManager
---@field init fun(self: enemy.StatsManager, opts: enemy.StatsManager.Opts)
---@field private enemy vibes.Enemy
---@field result enemy.Stats Resulting stats
local EnemyStatsManager = class "vibes.enemy-stats-manager"

---@class enemy.StatsManager.Opts
---@field enemy vibes.Enemy

---@param opts enemy.StatsManager.Opts
function EnemyStatsManager:init(opts)
  self.enemy = opts.enemy
  self.result = opts.enemy.stats_base:clone()
end

--- Hook for calling update on the tower, possibly could be called "compute", that's what I had before
function EnemyStatsManager:update(_dt)
  self.result = self.enemy.stats_base:clone()

  ---@type enemy.StatOperation[]
  local operations = {}

  if self.enemy.statuses.hexed then
    table.list_extend(operations, {
      EnemyStatOperation.new {
        field = EnemyStatField.SPEED,
        operation = StatOperation.new {
          kind = StatOperationKind.MUL_MULT,
          value = -0.5,
        },
      },
    })
  end

  State.gear_manager:for_gear_in_active_gear(function(gear)
    if gear:is_active_on_enemy(self.enemy) then
      table.list_extend(operations, gear:get_enemy_operations(self.enemy))
    end
  end)

  for _, tower in ipairs(State.towers) do
    -- Check all towers for enemy operations (not just EFFECT towers)
    local distance = self.enemy.position:distance(tower.position)
    if distance <= tower:get_range_in_distance() then
      -- Some towers have immobilize_enemy method (like ZombieHandsTower)
      if tower.immobilize_enemy then
        tower:immobilize_enemy(self.enemy)
      else
        table.list_extend(operations, tower:get_enemy_operations(self.enemy))
      end
    end
  end

  local level_operations =
    State.levels:get_current_level():get_enemy_operations(self.enemy)
  table.list_extend(operations, level_operations)

  for _, aura in ipairs(State.auras) do
    if aura:is_active_on_enemy(self.enemy) and aura.get_enemy_operations then
      table.list_extend(operations, aura:get_enemy_operations(self.enemy))
    end
  end

  -- for _, enhancement in ipairs(self.tower.enhancements) do
  --   if enhancement:is_active(self.tower) then
  --     table.list_extend(operations, enhancement:get_tower_operations(self.tower, _dt))
  --   end
  -- end

  for _, operation in ipairs(operations) do
    operation:apply_to_enemy_stats(self.result)
  end
end

return EnemyStatsManager
