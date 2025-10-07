local anim = require "vibes.anim"

--- @param el Element
--- @param child Element
--- @return number?
local function find_child(el, child)
  local idx = nil
  for i, c in ipairs(el.children) do
    if c == child then
      idx = i
      break
    end
  end
  return idx
end

local DEFAULT_ANIMATION_DURATION = 3

--- @alias ui.components.RenderFunc fun(self: Element)
--- @alias ui.components.UpdateFunc fun(self: Element, dt: number)
--- @alias ui.components.CoordinateCB fun(self: Element, evt: ui.components.UIMouseEvent, x: number, y: number)
--- @alias ui.components.ActionCB fun(self: Element, evt: ui.components.UIEvent): UIAction?
--- @alias ui.components.UICB fun(self: Element)

--- Optional drag callbacks that Elements may implement
--- @class Element.DraggableCallbacks
--- @field _drag_start fun(self: Element, evt: ui.components.UIMouseEvent)?
--- @field _drag fun(self: Element, evt: ui.components.UIMouseEvent)?
--- @field _drag_end fun(self: Element, evt: ui.components.UIMouseEvent)?

---@class (exact) Element.Shader
---@field source vibes.Shader,
---@field blend_mode love.BlendMode

---@class (exact) Element.DriveTargets
---@field entered number
---@field focused number
---@field pressed number
---@field dragged number
---@field created number
---@field removed number

-- TODO(hovered): This needs t o be switched
-- ---@field hovered number

---@class (exact) Element.AnimateStyle
---@field opacity number?
---@field scale number?
---@field color number[]?

--- @class (exact) Element.State Fields determining the state of the element.
--- @field interactable boolean Whether the element and ALL ITS CHILDREN are interactable.
--- @field draggable boolean Whether the element can be dragged.
--- @field debug boolean Whether the element and ALL ITS CHILDREN are in debug mode.
--- @field hidden boolean? Whether the element and ALL ITS CHILDREN should be hidden.
--- @field selected number? Whether the element is selected. Value is time in seconds.
--- @field _depth number The depth of the element in the tree.

--- @class Element : vibes.Class
--- @field new fun(box: ui.components.Box, opts?: Element.Opts): Element
--- @field init fun(self: Element, box: ui.components.Box, opts?: Element.Opts)
--- @field super Element?
--- @field parent Element?
--- @field _render ui.components.RenderFunc All Elements must have a _render function.
--- @field _update ui.components.UpdateFunc? Update is optional, since not all elements have things that update.
--- @field animator Animator
---
--- @field name string
--- @field children Element[]
--- @field state Element.State The calculated state of the element, accounting for parents.
--- @field _created_offset vibes.Position
---
--- TODO(z): Move this to Element.State
--- @field z number
---
-- Overridable Events for Elements
--- @field _mouse_enter ui.components.CoordinateCB?
--- @field _mouse_leave ui.components.CoordinateCB?
--- @field _mouse_moved ui.components.CoordinateCB?
--- @field _pressed ui.components.CoordinateCB?
--- @field _released ui.components.CoordinateCB?
--- @field _focus ui.components.ActionCB?
--- @field _blur ui.components.ActionCB?
--- @field _click ui.components.CoordinateCB?
---
--- @field _drag_state { started: boolean, offset: { x: number, y: number } }
--- @field _drag_start fun(self: Element, evt: ui.components.UIMouseEvent)?
--- @field _drag fun(self: Element, evt: ui.components.UIMouseEvent)?
--- @field _drag_end fun(self: Element, evt: ui.components.UIMouseEvent)?
---
--- @field ui_unselected? ui.components.ActionCB? TODO: I think we can remove this?
---
--- @field shaders Element.Shader[]
--
-- Public Fields
--- @field get_scale fun(self: Element): number
--- @field set_scale fun(self: Element, scale: number)
---
--- @field get_opacity fun(self: Element): number
--- @field set_opacity fun(self: Element, o: number)
--- @field get_color fun(self: Element): number[]
--- @field set_color fun(self: Element, c: number[])
--- @field get_interactable fun(self: Element): boolean
--- @field set_interactable fun(self: Element, i: boolean)
--- @field get_rotation fun(self: Element): number
--- @field set_rotation fun(self: Element, r: number)
--- @field is_hidden fun(self: Element): boolean
--- @field set_hidden fun(self: Element, hidden: boolean)
--- @field set_debug fun(self: Element, d: boolean)
--- @field is_debug_mode fun(self: Element): boolean
---
-- Dimension Properties
--- @field get_box fun(self: Element): ui.components.Box
--- @field get_relative_box fun(self: Element): ui.components.Box
--- @field get_pos fun(self: Element): vibes.Position
--- @field get_relative_pos fun(self: Element): vibes.Position
--- @field get_width fun(self: Element): number
--- @field get_height fun(self: Element): number
--- @field get_dim fun(self: Element): vibes.Position
--- @field get_geo fun(self: Element): number, number, number, number -- x, y, width, height; gets the height and width of a ui element
--- @field get_x fun(self: Element): number
--- @field get_y fun(self: Element): number
--
--- @field set_z fun(self: Element, z: number)
--- @field get_z fun(self: Element): number
--
--- Dragging (opt-in)
--- @field set_draggable fun(self: Element, enabled: boolean)
--- @field is_draggable fun(self: Element): boolean
--- @field is_dragging fun(self: Element): boolean
--- @field drag_start fun(self: Element, evt: ui.components.UIMouseEvent): UIAction?
--- @field drag fun(self: Element, evt: ui.components.UIMouseEvent): UIAction?
--- @field drag_end fun(self: Element, evt: ui.components.UIMouseEvent): UIAction?
--
-- Hierarchy Fields
--- @field swap_parent fun(self: Element, parent: Element)
--- @field append_child fun(self: Element, child: Element)
--- @field remove_child fun(self: Element, child: Element, hint?: number)
--- @field remove_all_children fun(self: Element)
---
--- Color instantiator
--- @field with_color fun(self: Element, color:vibes.Color, render_fn: fun())
--
-- Animation Fields
--- @field animate_to_absolute_position fun(self: Element, pos: vibes.Position, props?: any)
--- @field animate_style fun(self: Element, to: Element.AnimateStyle, props?: Animation.SharedProps): Element
---
-- Private Fields, do not use please :)
--- @field _flux_tweens table<string, Flux.Tween>
--- @field _post_update_hooks (fun(self: self))[] Functions to be called after the element has updated.
local Element = class("Element", {
  abstract = {
    _render = true,
  },
  forbidden = {
    -- render = true,
    click = true,
    single_click = true,
    double_click = true,
    -- TODO: Make all drag functions use the private methods
    drag_start = true,
    drag = true,
    drag_end = true,
    is_dragging = true,
  },
})

--- @class Element.NewOpts
--- @field x number
--- @field y number
--- @field w number
--- @field h number
--- @field render? fun(self: Element)

---@class Element.Props
---@field x number Relative x position
---@field y number Relative y position
---@field w number Width
---@field h number Height
---@field color number[]
---@field opacity number
---@field offset_x number Offset x, from relative position ???
---@field offset_y number Offset y, from relative position ???
---
---@field entered number Entered factor (0 idle, 1 entered).
---@field focused number Focused factor (0 idle, 1 focused).
---@field pressed number Pressed factor (0 idle, 1 pressed).
---@field dragged number Trackable dragged factor (0 idle, 1 dragged).
---@field created number Created factor (0 idle, 1 created). Set to 1 when the element is created.
---@field removed number Removed factor (0 idle, 1 removed). Set to 1 when the element is removed.

--- @class Element.Opts
--- @field name? string
--- @field z? number
--- @field interactable? boolean
--- @field hidden? boolean
--- @field debug? boolean
--- @field draggable? boolean
--- @field render? fun(self: Element)
--- @field created_offset? vibes.Position
--- @field shaders? Element.Shader[]
--- @field opacity? number

---@param box ui.components.Box
---@param opts Element.Opts
function Element:init(box, opts)
  opts = opts or {}
  validate({
    box = box,
  }, {
    box = Box,
  })
  validate(opts, {
    created_offset = Optional { Position },
  })

  opts = opts or {}

  -- This is because sometimes this are big bad and dumb. Someday we switch to interactive. KEKW
  ---@diagnostic disable-next-line: undefined-field
  assert(opts.interactive == nil, "this isn't a real property")

  self.z = F.if_nil(opts.z, 0)
  self.name = F.if_nil(opts.name, "BaseElement")
  self._created_offset = opts.created_offset or Position.zero()

  -- Note: _immediate_state is deprecated - use _animator.params instead

  self.animator = anim.new {
    color = { initial = { 1, 1, 1 }, rate = 4.0 },
    scale = { initial = 1, rate = 5.0 },
    rotation = { initial = 0, rate = 4.0 },
    opacity = { initial = 1, rate = 5.0 },
    x = { initial = box.position.x, rate = 5.0 },
    y = { initial = box.position.y, rate = 5.0 },
    w = { initial = box.width, rate = 5.0 },
    h = { initial = box.height, rate = 5.0 },

    -- Params
    offset_x = { initial = 0, rate = 3.0 },
    offset_y = { initial = 0, rate = 3.0 },

    -- Drive targets
    entered = { initial = 0.0, rate = 7.0 },
    focused = { initial = 0.0, rate = 7.0 },
    pressed = { initial = 0.0, rate = 9.0 },
    dragged = { initial = 0.0, rate = 8.0 },
    created = { initial = 0.0, rate = 4.0 },
    removed = { initial = 0.0, rate = 4.0 },
  }

  self.targets = {
    entered = 0,
    focused = 0,
    pressed = 0,
    dragged = 0,
    created = 1,
    removed = 0,
  }

  ---@type Element.Props
  ---@diagnostic disable-next-line: assign-type-mismatch
  self._props = self.animator.params

  -- TODO: We should find a better way to copy some of these into the props initially.
  self._props.x = box.position.x
  self._props.y = box.position.y
  self._props.w = box.width
  self._props.h = box.height
  self._props.opacity = opts.opacity or 1

  self.state = {
    debug = F.if_nil(opts.debug, false),
    interactable = F.if_nil(opts.interactable, false),
    hidden = F.if_nil(opts.hidden, false),
    _depth = 0,
    drag_offset = { x = 0, y = 0 },
    draggable = F.if_nil(opts.draggable, false),
  }

  self._drag_state = {
    started = false,
    offset = { x = 0, y = 0 },
  }

  self.children = {}
  self.shaders = {}

  self._flux_tweens = {}
  self._post_update_hooks = {}

  if opts.render then
    assert(not self._render, "render function already set")
    self._render = opts.render
  end
end

--- {{{ Getter / Setters (dependent on parents)

-- Style Properties (using _props for animated values)
function Element:get_opacity()
  local opacity = 1
  if self.parent then
    opacity = self.parent:get_opacity()
  end

  return opacity * self._props.opacity
end
function Element:set_opacity(opacity)
  anim.tween(self.animator, "opacity", opacity)
end

function Element:get_scale()
  return self._props.scale --[[@as number]]
end
function Element:set_scale(scale) anim.tween(self.animator, "scale", scale) end

function Element:get_rotation()
  local parent_rotation = self.parent and self.parent:get_rotation() or 0
  return parent_rotation + self._props.rotation --[[@as number]]
end
function Element:set_rotation(rotation)
  anim.tween(self.animator, "rotation", rotation)
end

function Element:get_color()
  return self._props.color --[[@as number[] ]]
end
function Element:set_color(color) anim.tween(self.animator, "color", color) end

-- State Properties
function Element:is_interactable()
  return self.state.interactable and not self.state.hidden
end

function Element:set_interactable(interactable)
  self.state.interactable = interactable
end

function Element:is_hidden() return self.state.hidden end
function Element:set_hidden(hidden) self.state.hidden = hidden end
function Element:set_debug(debug) self.state.debug = debug end

function Element:is_entered() return self.targets.entered == 1 end
function Element:is_focused() return self.targets.focused == 1 end
function Element:is_pressed() return self.targets.pressed == 1 end
function Element:is_dragged() return self.targets.dragged == 1 end

-- }}}

-- {{{ Animation
function Element:clear_animate()
  while #self._flux_tweens > 0 do
    local tween = table.remove(self._flux_tweens)
    Animation:remove_animation(tween)
  end
end

--- Moves a box to an absolute position, accounting for the parent's position.
--- @param pos vibes.Position
--- @param props any
function Element:animate_to_absolute_position(pos, props)
  props = props or {}
  local duration = props.duration or 0.2
  local ease = props.ease or anim.Ease.easeInOutCubic

  -- Convert string ease to function if needed
  if type(ease) == "string" then
    if ease == "linear" then
      ease = anim.Ease.linear
    elseif ease == "quadinout" or ease == "easeInOutCubic" then
      ease = anim.Ease.easeInOutCubic
    elseif ease == "quadout" or ease == "easeOut" then
      ease = anim.Ease.easeOut
    elseif ease == "smoothstep" then
      ease = anim.Ease.smoothstep
    else
      -- Default to linear for unknown string values
      ease = anim.Ease.linear
    end
  end

  anim.tween(self.animator, "x", pos.x, duration, ease)
  anim.tween(self.animator, "y", pos.y, duration, ease)

  -- Handle on_complete callback using State callback system
  if props.on_complete then
    State:add_callback(props.on_complete, duration)
  end
end

--- }}}

--- {{{ TODO THIS IS NOT WHAT I WANT IN THE END
--- stylua: ignore start
function Element:set_x(x) self._props.x = x end
function Element:set_y(y) self._props.y = y end
function Element:set_pos(pos)
  self._props.x = pos.x
  self._props.y = pos.y
end
function Element:set_width(width) self._props.w = width end
function Element:set_height(height) self._props.h = height end

function Element:set_dim(width, height)
  self._props.w = width
  self._props.h = height
end

function Element:get_box()
  local x, y, w, h = self:get_geo()
  return Box.new(Position.new(x, y), w, h)
end

function Element:get_width()
  local _, _, w, _ = self:get_geo()
  return w
end
function Element:get_height()
  local _, _, _, h = self:get_geo()
  return h
end

function Element:get_x()
  local x = self:get_geo()
  return x
end

function Element:get_y()
  local _, y = self:get_geo()
  return y
end

--- stylua: ignore end
--- }}}

function Element:__tostring()
  return string.format(
    "Element(%s, z=%s, %s)",
    self.name,
    self.z,
    self.state.interactable
  )
end

--- @return vibes.Position
function Element:get_pos()
  local x, y = self:get_geo()
  return Position.new(x, y)
end

function Element:_get_root_geo()
  local x, y, w, h = self._props.x, self._props.y, self._props.w, self._props.h

  local offset_x, offset_y = self._props.offset_x, self._props.offset_y
  x = x + offset_x
  y = y + offset_y

  if self.parent then
    local parent_x, parent_y = self.parent:get_geo()
    x = x + parent_x
    y = y + parent_y
  end

  return x, y, w, h
end

function Element:_get_drag_offset()
  local drag_offset = self._drag_state.offset
  return {
    x = drag_offset.x,
    y = drag_offset.y,
  }
end

function Element:_get_drag_position(drag_offset)
  return {
    x = State.mouse.x - drag_offset.x,
    y = State.mouse.y - drag_offset.y,
  }
end

--- @return number x Absolute x position
--- @return number y Absolute y position
--- @return number w Absolute width, (not accounting for scaling)
--- @return number h Absolute height, (not accounting for scaling)
function Element:get_geo()
  local x, y, w, h = self:_get_root_geo()

  local created = E.linear(1 - self._props.created)
  x = created * self._created_offset.x + x
  y = created * self._created_offset.y + y

  -- NOT A ZERO OR ONE (BOOLEAN) ITS A SPECTRUM (BEGINS FAVORITE WORD) FROM 0 TO 1
  local dragged = self._props.dragged

  if dragged > 0 then
    -- Calculate the initial grab position based on current element size and stored percentages
    -- local grab_x = x +  self._drag_state.offset.x
    -- local grab_y = y +  self._drag_state.offset.y

    local drag_offset = self:_get_drag_offset()
    local drag_position = self:_get_drag_position(drag_offset)

    x = (1 - dragged) * x + dragged * drag_position.x
    y = (1 - dragged) * y + dragged * drag_position.y
  end

  return x, y, w, h
end

--- @param dt number
function Element:update(dt)
  if self.parent then
    -- TODO: Decide what happens for opacity and stuff here too?...
    -- https://github.com/Mordoria/unnamed_game_1/commit/ddb85932f96ebd04c2feb582245866ed08c4a39e

    self.z = math.max(self.z, self.parent.z + 1)

    if self.parent.state.debug then
      self.state.debug = true
    end
  end

  local anim = require "vibes.anim"
  anim.drive(self.animator, self.targets, dt)
  anim.update(self.animator, dt)

  if self._update then
    self:_update(dt)
  end

  for _, child in ipairs(self.children) do
    child:update(dt)
  end

  for _, hook in ipairs(self._post_update_hooks) do
    hook(self)
  end
end

function Element:is_debug_mode() return self.state.debug end

---@param shader vibes.Shader
---@param blend_mode love.BlendMode
function Element:add_shader(shader, blend_mode)
  table.insert(self.shaders, { source = shader, blend_mode = blend_mode })
end

---@param shader vibes.Shader
function Element:remove_shader(shader)
  for idx, s in ipairs(self.shaders) do
    if s.source.id == shader.id then
      table.remove(self.shaders, idx)
    end
  end
end

function Element:render()
  if self.state.hidden then
    return
  end

  love.graphics.push()

  for _, ref in ipairs(self.shaders) do
    love.graphics.setShader(ref.source.shader)
    love.graphics.setBlendMode(ref.blend_mode)
  end

  local opacity = self:get_opacity()

  love.graphics.setColor(1, 1, 1, opacity)

  local x, y, w, h = self:get_geo()

  local rotation = self:get_rotation()
  if rotation ~= 0 then
    love.graphics.translate(x + w / 2, y + h / 2)
    love.graphics.rotate(rotation)
    love.graphics.translate(-(x + w / 2), -(y + h / 2))
  end

  local scale = self:get_scale()
  if scale ~= 1 then
    love.graphics.translate(x + w / 2, y + h / 2)
    love.graphics.scale(scale, scale)
    love.graphics.translate(-(x + w / 2), -(y + h / 2))
  end

  -- if (self.state._depth or 0) < 3 then
  --   print(
  --     string.format("%srender:%s", ("  "):rep(self.state._depth or 0), self)
  --   )
  -- end

  local ok, err = pcall(self._render, self)
  if not ok then
    print_once_per_second("ERROR: " .. err)

    love.graphics.setFont(Asset.fonts.default_18)
    love.graphics.setColor(1, 0, 0)
    love.graphics.print(err, 10, 200)
    love.graphics.setColor(1, 1, 1)

    -- Pop and unset shader and blend on err
    if #self.shaders > 0 then
      print "trigger"
      love.graphics.setShader()
      love.graphics.setBlendMode "alpha"
    end
    love.graphics.pop()
    return
  end

  -- TODO: probably need to take this check out.  it is pretty expensive..
  if self:is_debug_mode() then
    local x, y, _, _ = self:get_geo()
    love.graphics.setFont(Asset.fonts.default_18)
    love.graphics.printf(
      -- string.format("%s: %s", self, self.z),
      string.format("%s", self.z),
      x,
      y,
      Config.window_size.width,
      "justify"
    )

    love.graphics.setColor(1, 0, 0)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", self:get_geo())
    love.graphics.setColor(1, 1, 1)
  end

  -- TODO(z): There is some annoyance here that differing z-values of children
  -- can result in some weird edge cases, but for now I think we just try
  -- and be a little bit careful with Z and it won't be an issue.
  local children = table.copy(self.children)
  table.sort(children, function(a, b) return a.z < b.z end)

  for _, child in ipairs(children) do
    child:render()
  end

  if #self.shaders > 0 then
    love.graphics.setShader()
    love.graphics.setBlendMode "alpha"
  end

  love.graphics.pop()
end

--- @NOTE append_tooltip and remove_tooltip are for calling up the tree until we reach the RootElement
--- Check out the RootElement for more information
--- @param tooltip Element
function Element:append_tooltip(tooltip)
  assert(
    tooltip._type == "ui.components.Tooltip",
    "tooltip provided is not a tooltip"
  )
  assert(self.parent, "element must have a parent to append a tooltip")
  self.parent:append_tooltip(tooltip)
end

--- @NOTE append_tooltip and remove_tooltip are for calling up the tree until we reach the RootElement
--- Check out the RootElement for more information
--- @param tooltip Element
function Element:remove_tooltip(tooltip)
  assert(
    tooltip._type == "ui.components.Tooltip",
    "tooltip provided is not a tooltip"
  )
  assert(self.parent, "element must have a parent to remove a tooltip")
  self.parent:remove_tooltip(tooltip)
end

---@param parent Element
function Element:swap_parent(parent)
  local current_pos = self:get_pos()
  self.parent:remove_child(self)
  parent:append_child(self)

  self:set_x(current_pos.x)
  self:set_y(current_pos.y)
end

--- @param el Element
function Element:append_child(el)
  assert(
    Element.is(el),
    "element provided is in fact NOT AN ELEMENT!  To reddit!!"
  )
  el.parent = self
  table.insert(self.children, el)
end

--- @param from Element
--- @param to Element
function Element:swap_children(from, to)
  local f_idx = find_child(self, from)
  local t_idx = find_child(self, to)

  assert(f_idx and t_idx, "passed in _non_ child in swapping children")
  self.children[f_idx] = to
  self.children[t_idx] = from
end

---@param el Element
---@return boolean
function Element:is_child(el) return el.parent == self end

--- @param el Element
--- @param hint number? If you know where the element is, you can pass this here. Just makes it go zoom.
function Element:remove_child(el, hint)
  assert(Element.is(el))

  -- If parent reference doesn't match, just remove from children array if found
  if el.parent ~= self then
    if hint and el == self.children[hint] then
      table.remove(self.children, hint)
      if type(el) == "vibes.ui.text-box" then
        State.focused_text_box = nil
      end
      return
    end

    for idx, child in ipairs(self.children) do
      if child == el then
        table.remove(self.children, idx)
        if type(el) == "vibes.ui.text-box" then
          State.focused_text_box = nil
        end
        return
      end
    end

    -- Element is not in children array, nothing to do
    return
  end

  el.parent = nil

  -- TODO: I do not like special casing text box here,
  -- we should remove this, or have a "post-remove" hook
  -- that elements can call.

  if hint then
    if el == self.children[hint] then
      table.remove(self.children, hint)

      if type(el) == "vibes.ui.text-box" then
        State.focused_text_box = nil
      end
      return
    end
  end

  for idx, child in ipairs(self.children) do
    if child == el then
      table.remove(self.children, idx)
      if type(el) == "vibes.ui.text-box" then
        State.focused_text_box = nil
      end

      return
    end
  end

  error "unable to find the child element you passed in"
end

function Element:remove_from_parent()
  if not self.parent then
    return
  end

  self.parent:remove_child(self)
end

--- Properly removes all children from the element
function Element:remove_all_children()
  while #self.children > 0 do
    local idx = #self.children
    local child = self.children[idx]
    if child.parent ~= self then
      -- Child reference is stale; purge without asserting
      table.remove(self.children, idx)
    else
      self:remove_child(child, idx)
    end
  end
end

local function coords_contains_x_y(rx, ry, rw, rh, x, y)
  return x >= rx and x <= rx + rw and y >= ry and y <= ry + rh
end

function Element:contains_absolute_x_y(x, y)
  local rx, ry, rw, rh = self:get_geo()
  local rotation = self:get_rotation()
  local scale = self:get_scale()

  if rotation == 0 and scale == 1 then
    return coords_contains_x_y(rx, ry, rw, rh, x, y)
  end

  local cx, cy = rx + rw / 2, ry + rh / 2
  local dx, dy = x - cx, y - cy

  local local_x = dx
  local local_y = dy

  if rotation ~= 0 then
    local cos_r = math.cos(-rotation)
    local sin_r = math.sin(-rotation)
    local rotated_x = dx * cos_r - dy * sin_r
    local rotated_y = dx * sin_r + dy * cos_r
    local_x, local_y = rotated_x, rotated_y
  end

  if scale ~= 1 then
    local scaled_half_w = (rw * scale) / 2
    local scaled_half_h = (rh * scale) / 2
    return math.abs(local_x) <= scaled_half_w
      and math.abs(local_y) <= scaled_half_h
  end

  local half_w = rw / 2
  local half_h = rh / 2
  return math.abs(local_x) <= half_w and math.abs(local_y) <= half_h
end

---@param evt ui.components.UIMouseEvent
---@param x number
---@param y number
function Element:mouse_enter(evt, x, y)
  assert(evt.type == "mouse")

  if self._mouse_enter then
    return self:_mouse_enter(evt, x, y)
  end
end

--- @param evt ui.components.UIMouseEvent
---@param x number
---@param y number
function Element:mouse_leave(evt, x, y)
  assert(evt.type == "mouse")

  if self._mouse_leave then
    return self:_mouse_leave(evt, x, y)
  end
end

--- @param evt ui.components.UIMouseEvent
---@param x number
---@param y number
function Element:mouse_moved(evt, x, y)
  assert(evt.type == "mouse")

  if self._mouse_moved then
    return self:_mouse_moved(evt, x, y)
  end
end

--- @param evt ui.components.UIClickEvent
---@param x number
---@param y number
function Element:click(evt, x, y)
  assert(evt.type == "click")

  if self._click then
    return self:_click(evt, x, y)
  end
end

--- @param evt ui.components.UIPressedEvent
---@param x number
---@param y number
function Element:pressed(evt, x, y)
  assert(evt.type == "pressed")

  if self._pressed then
    return self:_pressed(evt, x, y)
  end
end

--- @param evt ui.components.UIPressedEvent
---@param x number
---@param y number
function Element:released(evt, x, y)
  assert(evt.type == "released")
  if self._released then
    return self:_released(evt, x, y)
  end
end

--- Focus happens when the mouse enters the element AND is the top most element.
--- that means that a mouse may enter / exit differently than the focus / blur
--- @param evt ui.components.UIEvent
function Element:focus(evt)
  assert(evt.type == "focus")

  if self._focus then
    return self:_focus(evt)
  end
end

--- Blur happens when the mouse enters the element AND is the top most element.
--- that means that a mouse may enter / exit differently than the focus / blur
--- @param evt ui.components.UIEvent
function Element:blur(evt)
  assert(evt.type == "blur")

  if self._blur then
    return self:_blur(evt)
  end
end

function Element:set_z(z) self.z = z end
function Element:get_z() return self.z end

---@param color vibes.Color
---@param render_fn fun(vibes.Color)
function Element:with_color(color, render_fn)
  color = Color.new(unpack(color))
  local opacity = color[4] * self:get_opacity()

  local current_color = Color.new(love.graphics.getColor())

  love.graphics.setColor(color:opacity(opacity))

  render_fn()

  love.graphics.setColor(current_color)
end

-- {{{ Dragging (opt-in API)

--- Enable or disable dragging for this element.
--- @param enabled boolean
function Element:set_draggable(enabled) self.state.draggable = enabled end

--- Returns whether dragging is enabled for this element.
--- @return boolean
function Element:is_draggable() return self.state.draggable end

--- Returns true if this element is currently being dragged.
--- @return boolean
function Element:is_dragging() return self.targets.dragged == 1 end

--- Begin a drag interaction. No-op if dragging is disabled or not enabled.
--- @param evt ui.components.UIMouseEvent
--- @return UIAction?
function Element:drag_start(evt)
  local x, y = self:_get_root_geo()

  self._drag_state.started = true
  self._drag_state.offset = {
    x = (evt.x - x),
    y = (evt.y - y),
  }

  if self._drag_start then
    self:_drag_start(evt)
  end

  return UIAction.HANDLED
end

--- Continue a drag interaction. No-op if not currently dragging or disabled.
--- @param evt ui.components.UIMouseEvent
--- @return UIAction?
function Element:drag(evt)
  if not self._drag_state.started then
    self._drag_state.started = true
    self:drag_start(evt)
  end

  if self._drag then
    self:_drag(evt)
  end

  return UIAction.HANDLED
end

--- End a drag interaction. No-op if not currently dragging or disabled.
--- @param evt ui.components.UIMouseEvent
--- @return UIAction?
function Element:drag_end(evt)
  self._drag_state.started = false
  self._drag_state.offset = { x = 0, y = 0 }

  if self._drag_end then
    self:_drag_end(evt)
  end

  return UIAction.HANDLED
end

-- }}}

function Element:animate_style(style, props)
  props = props or {}
  local duration = props.duration or 0.2
  local ease = props.ease or anim.Ease.linear

  -- Convert string ease to function if needed
  if type(ease) == "string" then
    if ease == "linear" then
      ease = anim.Ease.linear
    elseif ease == "quadinout" or ease == "easeInOutCubic" then
      ease = anim.Ease.easeInOutCubic
    elseif ease == "quadout" or ease == "easeOut" then
      ease = anim.Ease.easeOut
    elseif ease == "smoothstep" then
      ease = anim.Ease.smoothstep
    else
      -- Default to linear for unknown string values
      ease = anim.Ease.linear
    end
  end

  for k, v in pairs(style) do
    anim.tween(self.animator, k, v, duration, ease)
  end

  -- Handle on_complete callback using State callback system
  if props.on_complete then
    State:add_callback(props.on_complete, duration)
  end

  return self
end

return Element
