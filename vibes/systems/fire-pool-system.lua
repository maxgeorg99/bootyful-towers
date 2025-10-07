local GameFunctions = require "vibes.data.game-functions"
local system

---@class system.FirePool: vibes.System
---@field new fun(): system.FirePool
---@field init fun(self: system.FirePool)
local FirePoolSystem = class("vibes.system.FirePool", { super = System })
FirePoolSystem.name = "FirePoolSystem"

---@class vibes.FirePool.Opts
---@field position vibes.Position

---@class vibes.FirePool
---@field new fun(vibes.FirePool.Opts): vibes.FirePool
---@field init fun(self: vibes.FirePool, opts: vibes.FirePool.Opts)
---@field position vibes.Position
---@field stacks number
local FirePool = class "vibes.FirePool"

function FirePool:init(opts)
  self.position = opts.position
  self.stacks = 10
  self.radius = 1
  self.enemies_applied = {}
end

function FirePool:update(dt)
  -- TODO: this ticks down outside of a round
  -- potential fix?
  local mode = State:get_mode() --[[@as vibes.GameMode]]
  if mode.lifecycle ~= RoundLifecycle.ENEMIES_SPAWNING then
    return
  end

  self.stacks = self.stacks - dt
  if self.stacks <= 0 then
    return
  end

  local enemies = GameFunctions.enemies_within(self.position, self.radius)
  for _, enemy in ipairs(enemies) do
    if not self.enemies_applied[enemy.id] then
      self.enemies_applied[enemy.id] = true
      enemy:apply_fire_stack(nil, self.stacks)
    end
  end
end

function FirePool:draw()
  love.graphics.setColor(1, 1, 1, 1)

  -- local noise = love.math.noise(self.position.x + self.id, self.position.y + self.id)
  -- local scale = 1 + noise * 0.5
  local scale = 3 + math.min(self.stacks / 100, 0.4)

  local position = self.position:clone()
  Asset.animations.fire_1:draw(position, scale, false)

  position.x = position.x + 3
  Asset.animations.fire_2:draw(position, scale, false)

  position.x = position.x - 6
  Asset.animations.fire_3:draw(position, scale, false)
end

function FirePoolSystem:init() self.fire_pools = {} end

function FirePoolSystem:spawn_pool(position)
  table.insert(
    self.fire_pools,
    FirePool.new {
      position = position:clone(),
    }
  )
end

function FirePoolSystem:update(dt)
  for _, pool in ipairs(self.fire_pools) do
    pool:update(dt)
    if pool.stacks <= 0 then
      table.remove_item(self.fire_pools, pool)
    end
  end
end

function FirePoolSystem:draw()
  for _, pool in ipairs(self.fire_pools) do
    pool:draw()
  end
end

system = FirePoolSystem.new()

return system
