---@class system.Poison: vibes.System
---@field new fun(): system.Poison
---@field init fun(self: system.Poison)
local PoisonSystem = class("vibes.system.Poison", { super = System })
PoisonSystem.name = "PoisonSystem"

function PoisonSystem:init() self.next_tick = 0 end

function PoisonSystem:update(dt)
  self.next_tick = self.next_tick - dt
  if self.next_tick > 0 then
    return
  end

  self.next_tick = 1
  local poison_state = {
    poison_growth = 1,
  }

  State:for_each_active_hook(function(gear)
    if gear.hooks.on_poison_tick then
      gear.hooks.on_poison_tick(gear, poison_state)
    end
  end)

  for _, enemy in ipairs(State.enemies) do
    if enemy.poison_stacks >= 1 then
      State:damage_enemy {
        enemy = enemy,
        damage = enemy.poison_stacks,
        kind = DamageKind.POISON,
      }
    end

    -- INTENTIONAL DESIGN: Poison stacks grow over time rather than decay
    -- This creates an escalating damage effect that rewards sustained poison application
    -- Unlike fire stacks which decay, poison becomes increasingly deadly
    if enemy.poison_stacks > 0 then
      enemy.poison_stacks = enemy.poison_stacks + poison_state.poison_growth
    end
  end
end

function PoisonSystem:draw() end

return PoisonSystem.new()
