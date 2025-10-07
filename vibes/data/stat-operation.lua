---@class (exact) StatOperation
---@field new fun(opts: StatOperation.Opts): StatOperation
---@field init fun(self: StatOperation, opts: StatOperation.Opts)
---@field apply fun(self: StatOperation, target: vibes.Stat): vibes.Stat
---@field display_text fun(self: StatOperation): string
---@field kind StatOperationKind
---@field label string
---@field value number
--
-- Convenience functions
---@field add_base fun(value: number): StatOperation
---@field add_mult fun(value: number): StatOperation
---@field mul_mult fun(value: number): StatOperation
local StatOperation = class "StatOperation"

assert(
  Enum.length(StatOperationKind) == 3,
  "enum.StatOperationKind count has changed, Update StatOperation!"
)

StatOperationLabel = {
  [StatOperationKind.ADD_BASE] = "+",
  [StatOperationKind.ADD_MULT] = "+",
  [StatOperationKind.MUL_MULT] = "x",
}

---@class StatOperation.Opts
---@field kind StatOperationKind
---@field value number

---@param opts StatOperation.Opts
function StatOperation:init(opts)
  validate(opts, {
    kind = StatOperationKind,
    value = "number",
  })

  self.kind = opts.kind
  self.label = StatOperationLabel[opts.kind]
  self.value = opts.value
end

function StatOperation:clone()
  return StatOperation.new {
    kind = self.kind,
    value = self.value,
  }
end

---@param target vibes.Stat
---@return vibes.Stat
function StatOperation:apply(target)
  if self.kind == StatOperationKind.ADD_BASE then
    return Stat.new(target.base + self.value, target.mult)
  elseif self.kind == StatOperationKind.ADD_MULT then
    return Stat.new(target.base, target.mult + self.value)
  elseif self.kind == StatOperationKind.MUL_MULT then
    return Stat.new(target.base, target.mult * self.value)
  end

  error("Unknown StatOperationKind: " .. tostring(self.kind))
end

-- TODO: this definitely needs colors, etc. but this is at least a start.
---@return string
function StatOperation:display_text()
  if self.kind == StatOperationKind.ADD_BASE then
    return string.format("+%s Base", self.value)
  elseif self.kind == StatOperationKind.ADD_MULT then
    return string.format("+%s Mult", self.value)
  elseif self.kind == StatOperationKind.MUL_MULT then
    return string.format("*%s Mult", self.value)
  end

  error("Unknown StatOperationKind: " .. tostring(self.kind))
end

---@param value number
---@return StatOperation
function StatOperation.add_base(value)
  return StatOperation.new { kind = StatOperationKind.ADD_BASE, value = value }
end

---@param value number
---@return StatOperation
function StatOperation.add_mult(value)
  return StatOperation.new { kind = StatOperationKind.ADD_MULT, value = value }
end

---@param value number
---@return StatOperation
function StatOperation.mul_mult(value)
  return StatOperation.new { kind = StatOperationKind.MUL_MULT, value = value }
end

return StatOperation
