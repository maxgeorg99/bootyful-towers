local NumberToString = require "ui.components.number_to_string"
local Tower = require "vibes.tower.base"

---@class (exact) components.TowerUpgradeAnimation.Opts
---@field tower vibes.Tower
---@field upgrade tower.UpgradeOption|tower.EvolutionOption

---@class (exact) components.TowerUpgradeAnimation : Element
---@field new fun(opts: components.TowerUpgradeAnimation.Opts): components.TowerUpgradeAnimation
---@field init fun(self: components.TowerUpgradeAnimation, opts: components.TowerUpgradeAnimation.Opts)
---@field tower vibes.Tower
---@field upgrade tower.UpgradeOption|tower.EvolutionOption
---@field opacity number
---@field start_time number
local TowerUpgradeAnimation =
  class("components.TowerUpgradeAnimation", { super = Element })

---@param opts components.TowerUpgradeAnimation.Opts
function TowerUpgradeAnimation:init(opts)
  validate(opts, {
    tower = Tower,
    upgrade = "table", -- Can be either UpgradeOption or EvolutionOption
  })

  local box = Box.new(Position.zero(), 0, 0)
  Element.init(self, box)

  self.name = "TowerUpgradeAnimation"
  self.tower = opts.tower
  self.upgrade = opts.upgrade
  self.opacity = 1.0
  self.start_time = love.timer.getTime()
  self:set_interactable(false)
end

function TowerUpgradeAnimation:_get_icon()
  -- Handle upgrade options (have operations)
  if self.upgrade.operations and #self.upgrade.operations > 0 then
    local first_op = self.upgrade.operations[1]
    return Asset.icons[first_op.icon]
  end

  -- Handle evolution options (have hints)
  if self.upgrade.hints and #self.upgrade.hints > 0 then
    local first_hint = self.upgrade.hints[1]
    local field_icon = TowerStatFieldIcon[first_hint.field]
    return Asset.icons[field_icon]
  end

  -- Fallback icon
  return Asset.icons[IconType.UPGRADE]
end

function TowerUpgradeAnimation:_get_upgrade_text()
  -- Handle upgrade options (have operations)
  if self.upgrade.operations and #self.upgrade.operations > 0 then
    return NumberToString.base_upgrade_to_display(self.tower, self.upgrade)
  end

  -- Handle evolution options (show evolution name or hint)
  if self.upgrade.hints and #self.upgrade.hints > 0 then
    -- For evolutions, we could show the evolution name or a generic indicator
    return "EVO"
  end

  -- Fallback
  return "+?"
end

function TowerUpgradeAnimation:_render()
  local current_time = love.timer.getTime()
  local elapsed = current_time - self.start_time
  local duration = 1.0 -- 1 second total duration

  -- Calculate opacity (fade out over time)
  self.opacity = math.max(0, 1 - (elapsed / duration))

  -- Remove self when animation is complete
  if self.opacity <= 0 then
    self:remove_from_parent()
    return
  end

  -- Position to the left of the tower and float upward
  local tower_pos = self.tower.position:clone()
  local icon_size = 36
  local offset_x = -50 -- Position to the left of the tower (negative value)
  local base_offset_y = -20 -- Starting position (slightly above center)
  local float_distance = 30 -- How far up it floats in pixels

  -- Calculate floating animation (moves up over time)
  local float_progress = elapsed / duration
  local current_float = float_distance * float_progress

  local x = tower_pos.x + offset_x
  local y = tower_pos.y + base_offset_y - current_float -- Subtract to move up

  -- Draw a larger background circle for the icon
  love.graphics.push()
  love.graphics.setColor(0.2, 0.2, 0.2, self.opacity * 0.8)
  love.graphics.circle(
    "fill",
    x + icon_size / 2,
    y + icon_size / 2,
    icon_size / 2 + 6
  )

  -- Draw the upgrade/evolution icon
  local icon = self:_get_icon()
  if icon then
    love.graphics.setColor(1, 1, 1, self.opacity)
    love.graphics.draw(
      icon,
      x,
      y,
      0,
      icon_size / icon:getWidth(),
      icon_size / icon:getHeight()
    )
  end

  -- Draw the upgrade value text beneath the icon
  local upgrade_text = self:_get_upgrade_text()
  if upgrade_text then
    love.graphics.setFont(Asset.fonts.insignia_18)
    love.graphics.setColor(1, 1, 1, self.opacity)

    -- Center the text beneath the icon
    local text_y = y + icon_size + 8 -- 8 pixels below the icon
    love.graphics.printf(upgrade_text, x, text_y, icon_size, "center")
  end

  love.graphics.pop()
end

function TowerUpgradeAnimation:_update(dt)
  -- Animation is handled in _render based on time
end

return TowerUpgradeAnimation
