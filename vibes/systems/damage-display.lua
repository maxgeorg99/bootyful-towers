local Object = require "vendor.object"

---@class vibes.DamageNumber : vibes.Class, vibes.System
---@field new fun(position: vibes.Position, damage: number, kind: DamageKind): vibes.DamageNumber
---@field init fun(self: vibes.DamageNumber, position: vibes.Position, damage: number, kind: DamageKind)
---@field position vibes.Position
---@field rotation number
---@field damage number
---@field kind DamageKind
---@field lifetime number
---@field max_lifetime number
---@field velocity vibes.Position
---@field alpha number
---@field fire_particles any

local DamageNumber = class "vibes.DamageNumber"

---@param position vibes.Position
---@param damage number
---@param kind DamageKind
function DamageNumber:init(position, damage, kind)
  self.position = Position.new(position.x, position.y)
  self.rotation = 0.125 - math.random() * 0.25
  self.damage = damage
  self.kind = kind
  self.lifetime = 0
  self.max_lifetime = 1.0 -- 1 second lifetime
  self.velocity = Position.new(0, -50) -- Move up at 50 pixels per second
  self.alpha = 1.0
end

---@class vibes.DamageDisplay : vibes.Class, vibes.System
---@field new fun(): vibes.DamageDisplay
---@field init fun(self: vibes.DamageDisplay)
---@field name string
---@field damage_numbers vibes.DamageNumber[]
local DamageDisplay = class("vibes.DamageDisplay", { super = System })

function DamageDisplay:init()
  self.name = "DamageDisplay"

  self.damage_numbers = {}
  -- Register event handlers
  self._dispose_enemy_damage = EventBus:listen_enemy_damage(function(opts)
    ---@cast opts vibes.event.EnemyDamage

    local position = opts.enemy.position:clone()
    local damage = opts.damage
    self:spawn_damage_number(position, damage, opts.kind)
  end)
end

--- Clean up any event listeners and resources
function DamageDisplay:destroy()
  if self._dispose_enemy_damage then
    self._dispose_enemy_damage()
    self._dispose_enemy_damage = nil
  end
end

---@param position vibes.Position
---@param damage number
---@param kind DamageKind
function DamageDisplay:spawn_damage_number(position, damage, kind)
  if damage <= 0 then
    return
  end

  table.insert(
    self.damage_numbers,
    DamageNumber.new(Position.new(position.x, position.y - 20), damage, kind)
  )
end

function DamageDisplay:update(dt)
  -- Update and remove expired damage numbers
  for i = #self.damage_numbers, 1, -1 do
    local number = self.damage_numbers[i]
    number.lifetime = number.lifetime + dt
    number.position = number.position:add(number.velocity:scale(dt))
    --fade out on the latter part of the lifetime, clamp to 01
    local frac = 0.66
    local lifeCutoff = number.max_lifetime * frac
    local f = (number.lifetime - lifeCutoff) * (1 / frac)
    local decay = f / number.max_lifetime
    number.alpha = math.max(0, 1.0 - decay)

    if number.lifetime >= number.max_lifetime then
      table.remove(self.damage_numbers, i)
    end
  end
end

function DamageDisplay:draw()
  love.graphics.setFont(Asset.fonts.damage_number)
  for _, number in ipairs(self.damage_numbers) do
    -- Draw a black outline of the text
    love.graphics.setColor(0, 0, 0, number.alpha)
    love.graphics.print(
      tostring(math.floor(number.damage)),
      number.position.x + 2,
      number.position.y + 2,
      number.rotation,
      math.max(2, number.damage / 500),
      math.max(2, number.damage / 500)
    )

    local color
    if number.kind == DamageKind.FIRE then
      color = { 1, 0.1, 0.1, number.alpha }
    elseif number.kind == DamageKind.POISON then
      color = { 0.1, 1, 0.1, number.alpha }
    else
      color = { 1, 0.9, 0.9, number.alpha }
    end

    love.graphics.setColor(color)
    love.graphics.print(
      tostring(math.floor(number.damage)),
      number.position.x,
      number.position.y,
      number.rotation,
      math.max(2, number.damage / 500),
      math.max(2, number.damage / 500)
    )
  end
end

return DamageDisplay.new()
