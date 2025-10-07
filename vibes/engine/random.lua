---@class Random
---@field new fun(opts: Random.Opts): Random
---@field init fun(self: Random, opts: Random.Opts)
---@field name string
---@field seed number
---@field generator love.RandomGenerator
local Random = class "vibes.engine.Random"

---@class (exact) Random.Opts
---@field name string

---@param opts Random.Opts
function Random:init(opts)
  validate(opts, {
    name = "string",
  })

  self.name = opts.name
  self.seed = Config.seed
  self.generator = love.math.newRandomGenerator(self.seed)
end

function Random:random(...)
  if self.seed ~= Config.seed then
    self:init { name = self.name }
  end

  return self.generator:random(...)
end

---@generic T
---@param list T[]
---@param length number?
---@return T
function Random:of_list(list, length)
  length = length or #list
  local idx = self:random(length)
  return list[idx]
end

function Random:decimal_range(min, max)
  return min + self.generator:random() * (max - min)
end

function Random:of_enum(enum)
  local values = require("vibes.enum").values(enum)
  return self:of_list(values)
end

return Random
