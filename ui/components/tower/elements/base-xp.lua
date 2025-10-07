local BG_COLOR = { 36 / 255, 36 / 255, 36 / 255, 255 / 255 }
local BG_INNER_COLOR = { 92 / 255, 95 / 255, 92 / 255, 255 / 255 }
local XP_COLOR = { 62 / 255, 192 / 255, 56 / 255, 255 / 255 }

---@class (exact) components.TowerUIXP : Element
---@field new fun(tower: vibes.Tower, ): components.TowerUIXP
---@field init fun(self: components.TowerUIXP, tower: vibes.Tower)
---@field tower vibes.Tower
local TowerUIXP = class("components.TowerUIXP", { super = Element })

---@param tower vibes.Tower
function TowerUIXP:init(tower)
  local box = Box.new(Position.zero(), 0, 0)

  Element.init(self, box)

  self.name = "TowerUIXP"
  self.tower = tower
  self:set_interactable(false)
end

function TowerUIXP:_mouse_enter() return UIAction.HANDLED end

function TowerUIXP:_render()
  local pos = self.tower.position:clone()
  local w, h = 25, 50

  local x, y = pos.x, pos.y
  x = x + 25
  y = y - h

  love.graphics.push()
  love.graphics.setColor(BG_COLOR)
  love.graphics.rectangle("fill", x, y - 20, w, h + 20, 5, 5, 80)

  love.graphics.setColor(BG_INNER_COLOR)
  love.graphics.rectangle("fill", x + 5, y + 5, w - 10, h - 10, 3, 3, 80)

  local progress = self.tower:get_level_progress()
  if progress > 0 then
    love.graphics.setColor(XP_COLOR)

    local offset_h = (h - 10) * progress
    love.graphics.rectangle(
      "fill",
      x + 5,
      y + ((h - offset_h) - 5),
      (w - 10),
      offset_h,
      3,
      3,
      80
    )
  end

  love.graphics.setFont(Asset.fonts.insignia_18)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.printf(tostring(self.tower.level), x - 1, y - 15, w, "center")

  love.graphics.pop()
end

--- @param _dt number
function TowerUIXP:_update(_dt) end

function TowerUIXP:_pressed(a, b, c) end

function TowerUIXP:_mouse_leave() end

return TowerUIXP
