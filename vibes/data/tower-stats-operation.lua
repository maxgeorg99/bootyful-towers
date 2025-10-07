---@class tower.StatOperation
---@field new fun(opts: tower.StatOperation.Opts): tower.StatOperation
---@field init fun(self: tower.StatOperation, opts: tower.StatOperation.Opts)
---@field field TowerStatField
---@field icon IconType
---@field label string
---@field operation StatOperation
local TowerStatOperation = class "tower.StatOperation"

function TowerStatOperation:__tostring()
  return string.format(
    "TowerStatOperation(%s %s)",
    self.field,
    self.operation:display_text()
  )
end

---@class tower.StatOperation.Opts
---@field field TowerStatField
---@field operation StatOperation

---@param opts tower.StatOperation.Opts
function TowerStatOperation:init(opts)
  validate(opts, {
    field = TowerStatField,
    operation = StatOperation,
  })

  self.field = opts.field

  self.icon = TowerStatFieldIcon[opts.field]
  self.label = TowerStatFieldLabel[opts.field]

  self.operation = opts.operation
end

---@return tower.StatOperation
function TowerStatOperation:clone()
  return TowerStatOperation.new {
    field = self.field,
    operation = self.operation:clone(),
  }
end

---@param stats tower.Stats
function TowerStatOperation:apply_to_tower_stats(stats)
  stats[self.field] = self.operation:apply(stats[self.field])
end

---@param field TowerStatField
---@param kind StatOperationKind
---@param value number
---@return tower.StatOperation
local make_operation = function(field, kind, value)
  return TowerStatOperation.new {
    field = field,
    operation = StatOperation.new {
      kind = kind,
      value = value,
    },
  }
end

---@return tower.StatOperation
local make_base_add_operation = function(field, value)
  return make_operation(field, StatOperationKind.ADD_BASE, value)
end

---@return tower.StatOperation
function TowerStatOperation.base_damage(value)
  return make_base_add_operation(TowerStatField.DAMAGE, value)
end

---@return tower.StatOperation
function TowerStatOperation.mult_damage(value)
  return make_operation(
    TowerStatField.DAMAGE,
    StatOperationKind.ADD_MULT,
    value
  )
end

---@return tower.StatOperation
function TowerStatOperation.mul_mult_damage(value)
  return make_operation(
    TowerStatField.DAMAGE,
    StatOperationKind.MUL_MULT,
    value
  )
end

---@return tower.StatOperation
function TowerStatOperation.base_attack_speed(value)
  return make_base_add_operation(TowerStatField.ATTACK_SPEED, value)
end

---@return tower.StatOperation
function TowerStatOperation.mult_attack_speed(value)
  return make_operation(
    TowerStatField.ATTACK_SPEED,
    StatOperationKind.ADD_MULT,
    value
  )
end

---@return tower.StatOperation
function TowerStatOperation.mul_mult_attack_speed(value)
  return make_operation(
    TowerStatField.ATTACK_SPEED,
    StatOperationKind.MUL_MULT,
    value
  )
end

---@return tower.StatOperation
function TowerStatOperation.base_range(value)
  return make_base_add_operation(TowerStatField.RANGE, value)
end

---@return tower.StatOperation
function TowerStatOperation.mult_range(value)
  return make_operation(TowerStatField.RANGE, StatOperationKind.ADD_MULT, value)
end

---@return tower.StatOperation
function TowerStatOperation.mul_mult_range(value)
  return make_operation(TowerStatField.RANGE, StatOperationKind.MUL_MULT, value)
end

---@return tower.StatOperation
function TowerStatOperation.base_critical(value)
  return make_base_add_operation(TowerStatField.CRITICAL, value)
end

---@return tower.StatOperation
function TowerStatOperation.mult_critical(value)
  return make_operation(
    TowerStatField.CRITICAL,
    StatOperationKind.ADD_MULT,
    value
  )
end

---@return tower.StatOperation
function TowerStatOperation.mul_mult_critical(value)
  return make_operation(
    TowerStatField.CRITICAL,
    StatOperationKind.MUL_MULT,
    value
  )
end

---@return tower.StatOperation
function TowerStatOperation.base_durability(value)
  return make_base_add_operation(TowerStatField.DURABILITY, value)
end

---@return tower.StatOperation
function TowerStatOperation.base_aoe(value)
  return make_base_add_operation(TowerStatField.AOE, value)
end

---@return tower.StatOperation
function TowerStatOperation.mult_aoe(value)
  return make_operation(TowerStatField.AOE, StatOperationKind.ADD_MULT, value)
end

---@return tower.StatOperation
function TowerStatOperation.mul_mult_aoe(value)
  return make_operation(TowerStatField.AOE, StatOperationKind.MUL_MULT, value)
end

---@return tower.StatOperation
function TowerStatOperation.base_enemy_targets(value)
  return make_base_add_operation(TowerStatField.ENEMY_TARGETS, value)
end

return TowerStatOperation
