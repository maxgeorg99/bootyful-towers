---@class vibes.FireSystem: vibes.System
---@field new fun(): vibes.FireSystem
---@field init fun(self: vibes.FireSystem)
local FireSystem = class("vibes.fire-system", { super = System })
FireSystem.name = "FireSystem"

function FireSystem:init() self.last_tick = 0 end

function FireSystem:update()
  local now = TIME.now()
  if now - self.last_tick < 0.5 then
    return
  end

  self.last_tick = now

  local fire_state = {
    fire_growth = 1,
  }

  State.gear_manager:for_gear_in_active_gear(function(gear)
    if gear.hooks.on_fire_tick then
      gear.hooks.on_fire_tick(gear, fire_state)
    end
  end)

  for _, enemy in ipairs(State.enemies) do
    if enemy.fire_stacks >= 1 then
      State:damage_enemy {
        enemy = enemy,
        damage = enemy.fire_stacks,
        kind = DamageKind.FIRE,
      }
    end

    enemy.fire_stacks = math.max(0, enemy.fire_stacks - 1)

    -- Clear fire stack sources if no fire stacks remain
    if enemy.fire_stacks <= 0 then
      enemy.fire_stack_sources = {}
    end
  end
end

function FireSystem:draw() end

return FireSystem.new()
