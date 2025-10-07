local EnemyHealthBar = require "ui.components.enemy.health-bar"
local EnemyShieldBar = require "ui.components.enemy.shield-bar"
local EnemyTooltip = require "ui.components.enemy.tooltip"
local drawing = require "vibes.drawing"

---@class components.EnemySpawned : Element
---@field new fun( enemy: vibes.Enemy)
---@field init fun(self:components.EnemySpawned, enemy: vibes.Enemy)
---@field enemy vibes.Enemy
---@field cell vibes.Cell
---@field _blood_particles particles.Blood
---@field _fire_particles particles.Fire
---@field enemy_tooltip components.EnemyTooltip
local EnemySpawned = class("components.EnemySpawned", { super = Element })

---@param enemy vibes.Enemy
---@return components.EnemySpawned
function EnemySpawned:init(enemy)
  -- local scale = enemy.scale
  local scale_x = enemy.scale_x
  local scale_y = enemy.scale_y

  local width = enemy.texture:getWidth() * scale_x
  local height = enemy.texture:getHeight() * scale_y

  -- Position the UI element so the enemy draws from bottom-center
  -- The enemy.position is the bottom-center point, so we offset by half width and full height
  local pos = enemy.position:sub(Position.new(width / 2, height))
  Element.init(self, Box.new(pos, width, height), {
    name = "EnemySpawned",
  })

  -- self:set_debug(true)

  self.enemy = enemy
  self.cell = self.enemy.cell

  self._blood_particles =
    require("vibes.particles.blood").new { position = enemy.position }
  self._fire_particles =
    require("vibes.particles.fire").new { position = enemy.position }

  -- Make arrow/physical hits spawn short-lived blood bursts
  self._dispose_enemy_damage = EventBus:listen_enemy_damage(function(event)
    if event.enemy ~= self.enemy then
      return
    end
    if event.kind ~= DamageKind.PHYSICAL then
      return
    end

    -- Scale burst by damage amount a bit, clamp to a pleasant range
    local dmg = math.max(0, event.damage or 0)
    local strength = math.min(1, (dmg / 12))
    self._blood_particles:set_intensity(math.max(0.4, strength))
    self._blood_particles:burst(strength)
  end)

  -- TODO: Pick the right position
  -- TODO: This should work but I think I need to spend some time on layout
  -- self:append_child(Layout.vdiv {
  --   EnemyHealthBar.new {
  --     box = Box.new(Position.new(0, 15), 30, 10),
  --     enemy = self.enemy,
  --   },
  -- })

  self.base_width = self.enemy.texture:getWidth()
  self.base_height = self.enemy.texture:getHeight() * 2

  local bar_width = self.base_width * 0.5
  local bar_offset_x = (self.base_width - bar_width) / 2

  local health_bar_offset = 0
  self:append_child(EnemyHealthBar.new {
    box = Box.new(Position.new(bar_offset_x, health_bar_offset), bar_width, 10),
    enemy = self.enemy,
  })

  local shield_bar_height = 10
  self:append_child(EnemyShieldBar.new {
    box = Box.new(
      Position.new(bar_offset_x, health_bar_offset - shield_bar_height),
      bar_width,
      shield_bar_height
    ),
    enemy = self.enemy,
  })

  -- Create tooltip as child component (following tower pattern)
  -- local enemy_box = Box.new(Position.zero(), width, height)
  -- self.enemy_tooltip = EnemyTooltip.new {
  --   enemy = self.enemy,
  --   enemy_box = enemy_box,
  --   z = Z.TOOLTIP,
  -- }
  -- self:append_child(self.enemy_tooltip)
end

local Tauntoise = require "vibes.enemy.enemy-boss-tauntoise"
function EnemySpawned:get_scale()
  if Tauntoise.is(self.enemy) then
    return Element.get_scale(self)
  end

  return self._props.created * Element.get_scale(self)
    + (1 - self._props.created) * 0.2
end

function EnemySpawned:_mouse_enter(evt, x, y)
  -- self.enemy_tooltip:enter_from_enemy()
  return UIAction.HANDLED
end

function EnemySpawned:_mouse_leave(evt, x, y)
  -- self.enemy_tooltip:exit_enemy()
  return UIAction.HANDLED
end

-- Override render to use enemy's scale for UI scaling
function EnemySpawned:render()
  -- Temporarily set the element's scale to match the enemy's scale
  -- local original_scale = self:get_scale()
  -- self:set_scale(self.enemy.scale / 2) -- Divide by 2 since base enemy scale is 2

  -- Call the parent's render method
  Element.render(self)

  -- Restore original scale
  -- self:set_scale(original_scale)
end

function EnemySpawned:_update(_dt)
  local pos =
    self.enemy.position:sub(Position.new(self.base_width / 2, self.base_height))
  self:set_pos(pos)

  self._blood_particles:set_position(self.enemy.center)
  self._blood_particles:update(_dt)

  self._fire_particles:set_position(self.enemy.center)
  self._fire_particles:update(_dt)
  self._fire_particles:set_intensity(self.enemy.fire_stacks / 250)
end

function EnemySpawned:_render()
  love.graphics.push()
  drawing.draw_shadow(2, self.enemy.position.x, self.enemy.position.y, 0)

  -- Reset color for enemy texture
  love.graphics.setColor(1, 1, 1)

  -- if self.hit_flash and love.timer.getTime() - self.last_damage_time < 0.2 then
  --   love.graphics.setColor(1, 0.3, 0.3)
  -- end
  --
  -- -- Draw dots based on tier (1-5)
  -- for i = 1, self.tier do
  --   local x = self.position.x + (i - 1 - (self.tier - 1) / 2) * tierSpacing
  --   local y = self.position.y - 20 -- Position above the enemy
  --   love.graphics.circle("fill", x, y, tierSize)
  -- end

  if
    self.enemy.hit_flash
    and love.timer.getTime() - self.enemy.last_damage_time < 0.2
  then
    love.graphics.setColor(1, 0.3, 0.3)
  end

  self._blood_particles:draw()

  if self.enemy.fire_stacks > 0 then
    self._fire_particles:draw()
  end

  love.graphics.setColor(1, 1, 1)

  if self.enemy.animation then
    local flipped = self.enemy.flipped
    local scale = self.enemy.scale

    -- TODO: Teej, should do LSP smarts here.
    if self.enemy.statuses.hexed then
      local time = self.enemy.statuses.hexed_timer
      local r = math.sin(time * 2)
      local g = math.sin(time * 2 + 2)
      local b = math.sin(time * 2 + 4)
      love.graphics.setColor(r, g, b)
      flipped = not self.enemy.flipped

      scale = scale * 0.5
    end
    self.enemy.animation:draw(self.enemy.position, scale, flipped)
  else
    drawing.shifted_draw(
      self.enemy.texture,
      self.enemy.position,
      self.enemy.scale,
      self.enemy.flipped
    )
  end

  -- love.graphics.setColor(1, 0, 0)
  -- local center = self.enemy.center
  -- love.graphics.circle("line", center.x, center.y, 3)
  love.graphics.setColor(1, 1, 1)

  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.pop()
end

--- Cleanup listeners and particle systems
function EnemySpawned:destroy()
  if self._dispose_enemy_damage then
    self._dispose_enemy_damage()
    self._dispose_enemy_damage = nil
  end
  if self.parent then
    self.parent:remove_child(self)
  end
end

return EnemySpawned
