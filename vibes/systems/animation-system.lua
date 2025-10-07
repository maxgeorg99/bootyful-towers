local Flux = require "vendor.flux"

---@class Animation.Tween
---@field stop fun(self: Animation.Tween)

---@class Animation.SharedProps
---@field duration number
---@field delay? number
---@field ease? string
---@field on_complete? fun()

---@class vibes.AnimationSystem : vibes.Class, vibes.System
---@field new fun(): vibes.AnimationSystem
---@field init fun(self: vibes.AnimationSystem)
local Animation = class("vibes.AnimationSystem", { super = System })

function Animation:init() self.name = "AnimationSystem" end

function Animation:update(dt) Flux.update(dt) end

function Animation:draw() end

---@class Animation.MoveElementToAbsolutePositionProps : Animation.SharedProps
---@field el Element
---@field dst vibes.Position

---@param opts Animation.MoveElementToAbsolutePositionProps
function Animation:move_element_to_absolute_position(opts)
  -- Translate to account for element's relative position
  local dst = opts.dst

  local original_interactable = opts.el:is_interactable()
  opts.el:set_interactable(false)
  -- return self:move_box_to_absolute_position {
  --   box = opts.el:get_relative_box(),
  --   duration = opts.duration,
  --   dst = dst,
  --   on_complete = function()
  --     opts.el:set_interactable(original_interactable)

  --     if opts.on_complete then
  --       opts.on_complete()
  --     end
  --   end,
  -- }
end

---@class Animation.MoveBoxToAbsolutePositionProps : Animation.SharedProps
---@field box ui.components.Box
---@field dst vibes.Position

---@param opts Animation.MoveBoxToAbsolutePositionProps
---@return Animation.Tween
function Animation:move_box_to_absolute_position(opts)
  local dst = opts.dst:clone()

  return Flux.to(opts.box.position, opts.duration, {
    x = dst.x,
    y = dst.y,
  })
    :ease("quadinout")
    :oncomplete(function()
      if opts.on_complete then
        opts.on_complete()
      end
    end)
end

---@class Animation.MoveElementToNewAbsoluteBoxProps : Animation.SharedProps
---@field el Element
---@field box ui.components.Box

---@param opts Animation.MoveElementToNewAbsoluteBoxProps
function Animation:move_element_to_new_absolute_box(opts)
  local on_complete

  if opts.on_complete then
    local needed = 2
    on_complete = function()
      needed = needed - 1
      if needed == 0 then
        opts.on_complete()
      end
    end
  end

  local moves = {}

  table.insert(
    moves,
    self:move_box_to_absolute_position {
      box = opts.el:get_relative_box(),
      dst = opts.box.position,
      duration = opts.duration,
      on_complete = on_complete,
    }
  )

  table.insert(
    moves,
    Flux.to(opts.el:get_relative_box(), opts.duration, {
      width = opts.box.width,
      height = opts.box.height,
    })
      :ease("quadinout")
      :oncomplete(on_complete)
  )

  return moves
end

---@param obj any
---@param to any
---@param props? Animation.SharedProps
---@return Animation.Tween
function Animation:animate_property(obj, to, props)
  props = props or {}
  props.duration = props.duration or 0.2
  props.ease = props.ease or "quadinout"

  local tween = Flux.to(obj, props.duration, to):ease(props.ease)

  if props.delay then
    tween:delay(props.delay)
  end

  if props.on_complete then
    tween:oncomplete(props.on_complete)
  end

  return tween
end

function Animation:remove_animation(tween) Flux.remove(tween) end

---@param obj Element
function Animation:remove_box_animation(obj) Flux.remove(obj:get_relative_pos()) end

return Animation.new()
