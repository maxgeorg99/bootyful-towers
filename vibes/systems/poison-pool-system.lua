local GameFunctions = require "vibes.data.game-functions"

local system

---@class system.PoisonPool: vibes.System
---@field new fun(): system.PoisonPool
---@field init fun(self: system.PoisonPool)
local PoisonPoolSystem = class("vibes.system.PoisonPool", { super = System })
PoisonPoolSystem.name = "PoisonPoolSystem"

---@class vibes.PoisonPool.Opts
---@field position vibes.Position

---@class vibes.PoisonPool
---@field new fun(vibes.PoisonPool.Opts): vibes.PoisonPool
---@field init fun(self: vibes.PoisonPool, opts: vibes.PoisonPool.Opts)
---@field position vibes.Position
---@field stacks number
local PoisonPool = class "vibes.PoisonPool"

function PoisonPool:init(opts)
  self.position = opts.position
  self.stacks = 10
  self.radius = 1
  self.enemies_applied = {}
end

function PoisonPool:update()
  local enemies = GameFunctions.enemies_within(self.position, self.radius)
  for _, enemy in ipairs(enemies) do
    if not self.enemies_applied[enemy.id] then
      self.enemies_applied[enemy.id] = true

      if self.stacks <= 0 then
        table.remove_item(system.poison_pools, self)
        return
      end

      enemy:apply_poison_stack(nil, self.stacks)
      self.stacks = self.stacks - 1
    end
  end
end

function PoisonPool:draw()
  -- GameAnimationSystem:play_poison_pool(self.position, 0.1)

  love.graphics.setColor(1, 1, 1, 1)

  -- local noise = love.math.noise(self.position.x + self.id, self.position.y + self.id)
  -- local scale = 1 + noise * 0.5
  local scale = 3 + math.min(self.stacks / 100, 0.4)
  local position = self.position:clone()

  local position = self.position:clone()
  Asset.animations.poison_1:draw(position, scale, false)

  position.x = position.x + 3
  Asset.animations.poison_2:draw(position, scale, false)

  position.x = position.x - 6
  Asset.animations.poison_3:draw(position, scale, false)

  -- TODO: Probably need a true asset for this.
  -- love.graphics.setColor(0, 1, 0, 1)
  -- love.graphics.circle(
  --   "fill",
  --   self.position.x,
  --   self.position.y,
  --   self.radius * Config.grid.cell_size
  -- )

  -- love.graphics.printf(
  --   tostring(self.stacks),
  --   self.position.x,
  --   self.position.y,
  --   self.radius,
  --   "center"
  -- )
end

function PoisonPoolSystem:init() self.poison_pools = {} end

function PoisonPoolSystem:spawn_pool(position)
  table.insert(
    self.poison_pools,
    PoisonPool.new {
      position = position:clone(),
    }
  )
end

function PoisonPoolSystem:update()
  for _, pool in ipairs(self.poison_pools) do
    pool:update()
  end
end

function PoisonPoolSystem:draw()
  for _, pool in ipairs(self.poison_pools) do
    pool:draw()
  end
end

system = PoisonPoolSystem.new()

return system
