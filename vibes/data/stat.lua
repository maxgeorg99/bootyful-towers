--[[

Kinds of stat modifications:
- Add an amount to the base value
- Add an amount to the mult value
- Multiply the amount of the mult value

Kinds of attributes:
- Damage
- Range
- Attack Speed
- (todo) Crit Chance
- (todo) Multi-shot
- (todo) Ricochet
- (todo) energy cost
- (todo) card slots
- ... ?

--]]

---@class vibes.Stat : vibes.Class
---@field new fun(base: number, mult: number): vibes.Stat
---@field init fun(self: vibes.Stat, base: number, mult: number)
---@field base number The base value
---@field mult number The multiplier
---@field value number The value of the stat
local Stat = class "vibes.Stat"

---@param base number
---@param mult number
function Stat:init(base, mult)
  assert(type(base) == "number", "base must be a number")
  assert(type(mult) == "number", "mult must be a number")

  self.base = base
  self.mult = mult
  self.value = base * mult
end

function Stat:clone() return Stat.new(self.base, self.mult) end

function Stat:__tostring()
  return string.format(
    "Stat(base=%s, mult=%s, value=%s)",
    self.base,
    self.mult,
    self.value
  )
end

return Stat
