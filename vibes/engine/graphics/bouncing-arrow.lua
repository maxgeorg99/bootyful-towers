local anim = require "vibes.anim"

---@class vibes.engine.graphics.BouncingArrowOpts
---@field target_pos vibes.Position The position the arrow should point to
---@field color? table<number, number, number> Arrow color (default: {0, 1, 0})
---@field y_offset? number How far up and down to bounce (default: 30)
---@field duration? number Duration of each bounce animation (default: 1.0)

--- @class vibes.engine.graphics.BouncingArrow : Element
--- @field new fun(opts: vibes.engine.graphics.BouncingArrowOpts): vibes.engine.graphics.BouncingArrow
--- @field init fun(self: vibes.engine.graphics.BouncingArrow, opts: vibes.engine.graphics.BouncingArrowOpts)
--- @field target_pos vibes.Position
--- @field original_y number
--- @field current_y_offset number
--- @field color table<number, number, number>
--- @field y_offset number
--- @field duration number
--- @field icon ui.components.Icon
--- @field current_tween Animation.Tween?
--- @field is_bouncing boolean
local BouncingArrow =
  class("vibes.engine.graphics.BouncingArrow", { super = Element })

--- @param opts vibes.engine.graphics.BouncingArrowOpts
function BouncingArrow:init(opts)
  validate(opts, {
    target_pos = Position,
    color = "table?",
    y_offset = "number?",
    duration = "number?",
  })

  self.target_pos = opts.target_pos:clone()
  self.y_offset = opts.y_offset or 30
  self.duration = opts.duration or 1.0
  self.color = opts.color or { 0, 1, 0 }
  self.is_bouncing = true

  -- Position the element above the target position
  local box =
    Box.new(Position.new(self.target_pos.x, self.target_pos.y), 64, 64)
  Element.init(self, box)

  self.name = "BouncingArrow"
  self.z = 10 -- High z-index to render on top

  -- Store the original Y position relative to element coordinates
  self.original_y = 0 -- Relative to element position
  self.current_y_offset = 0 -- Current animation offset

  -- Create the icon that will be animated
  self.icon = Icon.new {
    type = IconType.DOWNARROW,
    scale = 0.3,
    color = self.color,
  }
  self:append_child(self.icon)

  -- Don't start animation immediately - let update handle lifecycle
end

-- Element lifecycle methods
function BouncingArrow:_update(dt)
  -- Check game lifecycle and enable/disable bouncing accordingly
  local mode = State:get_mode() --[[@as vibes.GameMode]]
  local should_bounce = mode.lifecycle == RoundLifecycle.PLAYER_TURN

  if should_bounce and not self.is_bouncing then
    self:_start_bounce_animation()
    self.is_bouncing = true
  elseif not should_bounce and self.is_bouncing then
    self:stop()
    self.is_bouncing = false
  end
end

-- Start the bouncing animation cycle
function BouncingArrow:_start_bounce_animation() self:_animate_down() end

-- Animate arrow moving down (towards target)
function BouncingArrow:_animate_down()
  anim.tween(
    self.icon.animator,
    "y",
    self.target_pos.y + self.y_offset,
    self.duration,
    anim.Ease.easeInOutCubic
  )
end

-- Animate arrow moving up (away from target)
function BouncingArrow:_animate_up()
  anim.tween(
    self.icon.animator,
    "y",
    self.target_pos.y - self.y_offset,
    self.duration,
    anim.Ease.easeInOutCubic
  )
end

-- Stop the bouncing animation
function BouncingArrow:stop()
  if self.current_tween then
    Animation:remove_animation(self.current_tween)
    self.current_tween = nil
  end
end

function BouncingArrow:_render() end

-- Required Element methods
function BouncingArrow:focus() end
function BouncingArrow:blur() end

return BouncingArrow
