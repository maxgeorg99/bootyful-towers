---@class enemy.StatOperation
---@field new fun(opts: enemy.StatOperation.Opts): enemy.StatOperation
---@field init fun(self: enemy.StatOperation, opts: enemy.StatOperation.Opts)
---@field field EnemyStatField
---@field operation StatOperation
local EnemyStatOperation = class "enemy.StatOperation"

---@class enemy.StatOperation.Opts
---@field field EnemyStatField
---@field operation StatOperation

---@param opts enemy.StatOperation.Opts
function EnemyStatOperation:init(opts)
  validate(opts, {
    field = EnemyStatField,
    operation = StatOperation,
  })

  self.field = opts.field
  self.operation = opts.operation
end

---@param stats enemy.Stats
function EnemyStatOperation:apply_to_enemy_stats(stats)
  stats[self.field] = self.operation:apply(stats[self.field])
end

return EnemyStatOperation
