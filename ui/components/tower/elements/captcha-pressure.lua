---@class (exact) components.CaptchaPressure : Element
---@field new fun(tower: vibes.Tower): components.CaptchaPressure
---@field init fun(self: components.CaptchaPressure, tower: vibes.Tower)
---@field tower vibes.Tower
---@field pulse number
local CaptchaPressure = class("components.CaptchaPressure", { super = Element })

--- Initialize the CaptchaPressure UI element
---@param tower vibes.Tower: the tower instance this UI represents
function CaptchaPressure:init(tower)
  local box = Box.new(Position.zero(), 0, 0)
  Element.init(self, box)

  self.name = "CaptchaPressure"
  self.tower = tower
  self.pulse = 0
  self:set_interactable(false)
end

function CaptchaPressure:_mouse_enter() return UIAction.HANDLED end

--- Update animation pulse
---@param dt number
function CaptchaPressure:_update(dt)
  self.pulse = (self.pulse + dt * 4) % (2 * math.pi)
end

--- Render the circular progress indicator around the tower
function CaptchaPressure:_render()
  -- Only render for captcha towers
  if self.tower._type ~= "vibes.CaptchaTower" then
    return
  end

  local tower = self.tower
  ---@cast tower vibes.CaptchaTower

  local progress = tower:get_captcha_progress()
  if progress <= 0 then
    return
  end

  local locked = tower:is_captcha_locked()

  local x = tower.position.x
  local y = tower.position.y

  local base_radius = math.max(22, math.floor(tower.texture:getWidth()))
  local radius = base_radius * 0.55

  love.graphics.push()

  -- Background ring
  love.graphics.setLineWidth(5)
  love.graphics.setColor(0, 0, 0, 0.35)
  love.graphics.circle("line", x, y, radius)

  -- Progress arc (0..2pi)
  local angle = progress * 2 * math.pi

  local r, g, b = 0.2, 0.75, 0.9 -- bluish
  if progress > 0.6 then
    r, g, b = 1.0, 0.6, 0.0
  end -- orange
  if progress > 0.85 or locked then
    r, g, b = 1.0, 0.2, 0.2
  end -- red when close/locked

  local alpha = 0.9
  if locked then
    -- Pulse when locked
    alpha = 0.6 + 0.4 * (0.5 + 0.5 * math.sin(self.pulse * 2))
  end

  love.graphics.setColor(r, g, b, alpha)
  love.graphics.arc(
    "line",
    "open",
    x,
    y,
    radius,
    -math.pi / 2,
    -math.pi / 2 + angle
  )

  -- Small dot at current angle
  local dx = math.cos(-math.pi / 2 + angle)
  local dy = math.sin(-math.pi / 2 + angle)
  love.graphics.setColor(r, g, b, math.min(1, alpha + 0.1))
  love.graphics.circle("fill", x + dx * radius, y + dy * radius, 3)

  love.graphics.pop()
end

function CaptchaPressure:_pressed() end
function CaptchaPressure:_mouse_leave() end

return CaptchaPressure
