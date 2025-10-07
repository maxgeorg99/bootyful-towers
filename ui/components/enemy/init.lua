local drawing = require "vibes.drawing"

---@class components.Enemy : Element
---@field new fun( enemy: vibes.Enemy)
---@field init fun(self:components.Enemy, enemy: vibes.Enemy)
---@field enemy vibes.Enemy
local Enemy = class("components.Enemy", { super = Element })

---@param enemy vibes.Enemy
---@return components.Enemy
function Enemy:init(enemy)
  local scale = 2
  local width = enemy.texture:getWidth() * scale
  local height = enemy.texture:getHeight() * scale
  local pos = enemy.position:sub(Position.new(width, height))
  Element.init(self, Box.new(pos, width, height))

  self.name = "Enemy"
  self._type = Enemy._type
  self.enemy = enemy
end

function Enemy:_mouse_enter() end
function Enemy:_mouse_leave() end

function Enemy:close() end

function Enemy:_update(_dt)
  local _, _, w, h = self:get_geo()
  --offset needed to ensure it matches draw orgin
  local pos = self.enemy.position:sub(Position.new(w / 2, h))
  self:set_pos(pos)
end

function Enemy:_render()
  love.graphics.push()
  drawing.draw_shadow(2, self.enemy.position.x, self.enemy.position.y, 0)

  -- Reset color for enemy texture
  love.graphics.setColor(1, 1, 1)

  if
    self.enemy.hit_flash
    and love.timer.getTime() - self.enemy.last_damage_time < 0.2
  then
    love.graphics.setColor(1, 0.3, 0.3)
  end

  self.enemy:_draw_texture()

  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.pop()
end

return Enemy
