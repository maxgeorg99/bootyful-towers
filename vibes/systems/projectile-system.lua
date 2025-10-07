local ProjectileSystem = class("vibes.ProjectileSystem", { super = System })
ProjectileSystem.name = "ProjectileSystem"

function ProjectileSystem:init() end

local valid_lifecycles = {
  [RoundLifecycle.ENEMIES_SPAWNING] = true,
  [RoundLifecycle.ENEMIES_DEFEATED] = true,
}

function ProjectileSystem:update(dt)
  if State.is_paused then
    return
  end

  if not valid_lifecycles[GAME.lifecycle] then
    return
  end

  for _, projectile in pairs(State.projectiles) do
    projectile:update(dt)
  end

  -- Look for collisions with enemies
  -- How bad is just MxN here?...
  -- Napkin math is maybe 100 enemies, 100 projectiles, 10000 iterations. Not so bad. Can fix later.
  for _, projectile in pairs(State.projectiles) do
    local candidates = {}

    for _, enemy in ipairs(State.enemies) do
      if projectile:collides_with(enemy) then
        table.insert(candidates, enemy)
      end
    end

    -- Find closest enemies to the projectile to collide with
    table.sort(
      candidates,
      ---@param a vibes.Enemy
      ---@param b vibes.Enemy
      function(a, b)
        return a.position:distance_squared(projectile.src)
          < b.position:distance_squared(projectile.src)
      end
    )

    -- Collide with the closest enemies, until the projectile is removed
    for _, enemy in ipairs(candidates) do
      if projectile:collide(enemy) then
        break
      end
    end
  end

  -- After processing collisions, remove any projectiles that reached target this tick
  for _, projectile in pairs(State.projectiles) do
    if projectile._pending_reached_target then
      projectile:_on_reached_target()
      projectile:remove()
    end
  end
end

function ProjectileSystem:draw()
  for _, projectile in pairs(State.projectiles) do
    projectile:draw()
  end
end

return ProjectileSystem.new()
