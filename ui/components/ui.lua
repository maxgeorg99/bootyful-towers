local Time = require "vibes.engine.time"

local RootElement = require "ui.components.root"
local Tooltip = require "ui.components.tooltip"
local UIEvent = require "ui.components.ui-event"

---@class ui.components.UI.Tickers
---@field x number
---@field y number
---@field time number
---@field _last_x number
---@field _last_y number

---@class ui.state.Mouse
---@field pressed Element?
---@field pressed_time number?
---@field pressed_x number?
---@field pressed_y number?

---@class ui.components.UIState
---@field mouse ui.state.Mouse
---@field user_message ui.components.Tooltip?
---@field tickers ui.components.UI.Tickers
---@field selected Element? The currently selected element, has retained state (not an immediate mode value)

---@class ui.components.UI
---@field new fun(width: number, height: number): ui.components.UI
---@field root ui.components.RootElement
---@field state ui.components.UIState
---@field _run_click_action fun(self: ui.components.UI, el: Element, x: number, y: number)
---@field _run_released_action fun(self: ui.components.UI, el: Element, x: number, y: number)
---@field _run_drag_end_action fun(self: ui.components.UI, el: Element, x: number, y: number)
---@field _run_focus_action fun(self: ui.components.UI, el: Element, x: number, y: number)
---@field _run_blur_action fun(self: ui.components.UI, el: Element, x: number, y: number)
---@field _run_mouse_enter_action fun(self: ui.components.UI, el: Element, x: number, y: number)
---@field _run_mouse_leave_action fun(self: ui.components.UI, el: Element, x: number, y: number)
local UIClass = class "ui.components.UI"

---@param width number
---@param height number
function UIClass:init(width, height)
  self.root = RootElement.new(width, height)
  self.state = {
    mouse = {
      pressed = nil,
      pressed_time = nil,
    },
    tickers = {
      _last_x = -1,
      _last_y = -1,
      time = 0,
      x = 0,
      y = 0,
    },
  }
end

function UIClass:reset(width, height)
  State.focused_text_box = nil

  self.root = RootElement.new(width, height)
  self.state = {
    mouse = {
      pressed = nil,
      pressed_time = nil,
    },
    tickers = {
      _last_x = -1,
      _last_y = -1,
      time = 0,
      x = 0,
      y = 0,
    },
  }
end

function UIClass:draw()
  logger.trace "UIClass:draw"
  self.root:render()
end

--- @class ui.components.DebugPrintOptions?
--- @field filter (fun(el: Element): boolean)?
--- @field stringify (fun(el: Element, prefix: string): string)?

---@param start_at Element?
---@param opts ui.components.DebugPrintOptions?
function UIClass:debug_print_ui(start_at, opts)
  start_at = start_at or self.root
  opts = opts or {}

  opts.filter = opts.filter or function(el) return el ~= nil end

  opts.stringify = opts.stringify
    or function(el, prefix)
      return prefix
        .. el.name
        .. "["
        .. tostring(el.id)
        .. "]"
        .. "("
        .. tostring(el:get_z())
        .. ", "
        .. el:get_box():string()
        .. ")"
    end

  local function recurse(el, depth)
    if not opts.filter(el) then
      return
    end

    local print_line = ""
    for _ = 1, depth do
      print_line = print_line .. " "
    end

    print(opts.stringify(el, print_line))
    for _, child in ipairs(el.children) do
      recurse(child, depth + 1)
    end
  end

  recurse(start_at, 1)
end

--- @param dt number
function UIClass:update(dt)
  local msg = Config.ui.message
  self.state.tickers.time = self.state.tickers.time + dt
  if
    self.state.user_message and self.state.tickers.time > msg.time_to_close
  then
    self:_remove_user_message()
  end

  -- Find element at current position, with highest z
  local element = self:_find_element_at_position(State.mouse.x, State.mouse.y)

  -- Update element targets based on immediate state
  self:_for_each(function(el)
    local is_focused = (el == element)
    local is_pressed = self.state.mouse.pressed == el
    local is_entered = el:contains_absolute_x_y(State.mouse.x, State.mouse.y)

    el.targets.pressed = is_pressed and 1 or 0

    -- Handle mouse enter/leave events
    if is_entered then
      if el.targets.entered ~= 1 then
        el.targets.entered = 1
        self:_run_mouse_enter_action(el, State.mouse.x, State.mouse.y)
      end
    else
      if el.targets.entered ~= 0 then
        el.targets.entered = 0
        self:_run_mouse_leave_action(el, State.mouse.x, State.mouse.y)
      end
    end

    if is_focused then
      if el.targets.focused ~= 1 then
        el.targets.focused = 1
        self:_run_focus_action(el, State.mouse.x, State.mouse.y)
      end
    else
      if el.targets.focused ~= 0 then
        el.targets.focused = 0
        self:_run_blur_action(el, State.mouse.x, State.mouse.y)
      end
    end

    if self.state.mouse.pressed and is_pressed and el:is_draggable() then
      local distance = math.sqrt(
        (self.state.mouse.pressed_x - State.mouse.x) ^ 2
          + (self.state.mouse.pressed_y - State.mouse.y) ^ 2
      )
      el.targets.dragged = distance > Config.ui.minimum_drag_amount and 1 or 0
    else
      el.targets.dragged = 0
    end
  end)

  self.root:update(dt)
end

--- @param x number
--- @param y number
--- @param filters? { interactable: boolean }
function UIClass:_find_element_at_position(x, y, filters)
  filters = filters or {}
  filters.interactable = F.if_nil(filters.interactable, true)

  ---@type Element
  local found = nil

  ---@param el Element
  local function search_tree(el)
    if el:is_hidden() then
      return nil
    end

    if el.z > (found and found.z or 0) and el:contains_absolute_x_y(x, y) then
      if filters.interactable then
        if el:is_interactable() then
          found = el
        end
      else
        found = el
      end
    end

    local containers = {
      el.children,
      el.reactive_container,
    }

    for _, container in ipairs(containers) do
      if container then
        for i = #container, 1, -1 do
          search_tree(container[i])
        end
      end
    end
  end

  search_tree(self.root)

  return found
end

--- For each element in the tree, call the callback.
---   If the callback returns true, then the iteration will stop for that tree.
--- @param cb fun(el: Element, depth: number): boolean?
--- @param _starting_el Element?
--- @param depth number?
function UIClass:_for_each(cb, _starting_el, depth)
  depth = depth or 1
  _starting_el = _starting_el or self.root

  if cb(_starting_el, depth) then
    return
  end

  for _, child in ipairs(_starting_el.children) do
    self:_for_each(cb, child, depth + 1)
  end
end

-- Handle mouse movements - immediate mode
function UIClass:mousemoved(x, y)
  -- Handle mouse events for the top element
  local element = self:_find_element_at_position(x, y)
  if element then
    local mm_evt = UIEvent.mouse(element, x, y)
    element:mouse_moved(mm_evt, x, y)
  end

  if self.state.mouse.pressed then
    local is_drag = math.sqrt(
      (self.state.mouse.pressed_x - x) ^ 2
        + (self.state.mouse.pressed_y - y) ^ 2
    ) > Config.ui.minimum_drag_amount

    if is_drag then
      -- self:_run_drag_action(self.state.mouse.pressed, x, y)
      self.state.mouse.pressed:drag(
        UIEvent.drag(self.state.mouse.pressed, x, y)
      )
    end
  end
end

-- Helper function to traverse parent chain and find handler
function UIClass:_find_and_execute_handler(el, event, handler_callback, ...)
  local curr = el
  while curr ~= nil do
    local action = handler_callback(curr, event, ...)
    -- print("process_action", curr, "handler", "action result", action)
    if action == UIAction.HANDLED then
      return true
    end
    curr = curr.parent
  end
  return false
end

function UIClass:_run_click_action(el, x, y)
  logger.debug("click_action: (%s) z=%s", el, el:get_z())

  local handled = self:_find_and_execute_handler(
    el,
    UIEvent.click(el, x, y),
    function(curr, event, x, y)
      if curr.click then
        return curr:click(event, x, y)
      end
      return nil
    end,
    x,
    y
  )
end

function UIClass:_run_released_action(el, x, y)
  logger.debug("released_action: (%s) z=%s", el, el:get_z())
end

function UIClass:_run_drag_end_action(el, x, y)
  logger.debug("drag_end_action: (%s) z=%s", el, el:get_z())

  local event = UIEvent.drag_end(el, x, y)
  self:_find_and_execute_handler(el, event, function(curr, event)
    if curr.drag_end then
      return curr:drag_end(event)
    end
    return nil
  end)
end

function UIClass:_run_focus_action(el, x, y)
  logger.debug("focus_action: (%s) z=%s", el, el:get_z())

  local event = UIEvent.focus(el, x, y)
  self:_find_and_execute_handler(el, event, function(curr, event)
    if curr.focus then
      return curr:focus(event)
    end
    return nil
  end)
end

function UIClass:_run_blur_action(el, x, y)
  logger.debug("blur_action: (%s) z=%s", el, el:get_z())

  local event = UIEvent.blur(el, x, y)
  self:_find_and_execute_handler(el, event, function(curr, event)
    if curr.blur then
      return curr:blur(event)
    end
    return nil
  end)
end

function UIClass:_run_mouse_enter_action(el, x, y)
  logger.debug(
    "mouse_enter_action: (%s) z=%s, has_mouse_enter: %s",
    el,
    el:get_z(),
    el._mouse_enter ~= nil
  )

  local event = UIEvent.mouse(el, x, y)
  self:_find_and_execute_handler(el, event, function(curr, event, x, y)
    if curr.mouse_enter then
      logger.debug("Calling mouse_enter on %s", curr)
      return curr:mouse_enter(event, x, y)
    end
    return nil
  end, x, y)
end

function UIClass:_run_mouse_leave_action(el, x, y)
  logger.debug("mouse_leave_action: (%s) z=%s", el, el:get_z())

  local event = UIEvent.mouse(el, x, y)
  self:_find_and_execute_handler(el, event, function(curr, event, x, y)
    if curr.mouse_leave then
      return curr:mouse_leave(event, x, y)
    end
    return nil
  end, x, y)
end

--- @param button number
--- @param x number
--- @param y number
function UIClass:mousepressed(button, x, y)
  if button ~= 1 then
    return
  end

  self.state.mouse.pressed_time = Time.now()
  self.state.mouse.pressed_x = x
  self.state.mouse.pressed_y = y

  local el = self:_find_element_at_position(x, y)
  if not el then
    logger.info "UI:mousepressed: no element found"
    return
  end

  -- Update mouse state
  self.state.mouse.pressed = el

  -- Trigger pressed event
  logger.debug("pressed_action: (%s) z=%s", el, el:get_z())

  local event = UIEvent.pressed(el, x, y)
  self:_find_and_execute_handler(el, event, function(curr, event, x, y)
    if curr.pressed then
      return curr:pressed(event, x, y)
    end
    return nil
  end, x, y)
end

--- @param button number
---@param x number
---@param y number
function UIClass:mousereleased(button, x, y)
  if button ~= 1 then
    return
  end

  local cleanup = function()
    self.state.mouse.pressed = nil
    self.state.mouse.pressed_time = nil
  end

  self.state.mouse.pressed_x = self.state.mouse.pressed_x or 0
  self.state.mouse.pressed_y = self.state.mouse.pressed_y or 0

  -- Determine if this was a click or drag
  local is_drag = math.sqrt(
    (self.state.mouse.pressed_x - x) ^ 2 + (self.state.mouse.pressed_y - y) ^ 2
  ) > Config.ui.minimum_drag_amount

  local el = self.state.mouse.pressed
  if not el then
    cleanup()
    return
  end

  if is_drag then
    self:_run_drag_end_action(el, x, y)
  else
    self:_run_click_action(el, x, y)
  end

  local event = UIEvent.released(el, x, y)
  self:_find_and_execute_handler(el, event, function(curr, event, x, y)
    if curr.released then
      return curr:released(event, x, y)
    end
    return nil
  end, x, y)

  cleanup()
end

function UIClass:_remove_user_message()
  assert(
    self.state.user_message,
    "you cannot call _remove_user_message if there is no user_message"
  )
  self.root:remove_tooltip(self.state.user_message)
  self.state.tickers._last_x = -1
  self.state.tickers._last_y = -1
  self.state.tickers.time = 0
  self.state.user_message = nil
end

function UIClass:create_user_message(text)
  self.state.user_message =
    Tooltip.new(text, self.root, 300, "WINDOW_TOP_CENTER")
  self.root:append_tooltip(self.state.user_message)
  self.state.tickers.x = 0
  self.state.tickers.y = 0
  self.state.tickers.time = 0
  self.state.tickers._last_x = -1
  self.state.tickers._last_y = -1
end

--- Programmatically focus a UI element, blurring the previously selected element
---@param el Element
function UIClass:focus_element(el)
  if not el then
    return
  end

  if self.state.selected == el then
    return
  end

  local prev = self.state.selected

  local x, y, w, h = el:get_geo()
  local cx, cy = x + w / 2, y + h / 2

  if prev then
    local px, py, pw, ph = prev:get_geo()
    prev.targets.focused = 0
    self:_run_blur_action(prev, px + pw / 2, py + ph / 2)
    logger.info("blur: %s", prev)
  end

  el.targets.focused = 1
  self:_run_focus_action(el, cx, cy)
end

--- Activate a UI element as if it were clicked (used for Enter key behavior)
---@param el Element
function UIClass:activate_element(el)
  if not el then
    return
  end
  local x, y, w, h = el:get_geo()
  local cx, cy = x + w / 2, y + h / 2
  self:_run_click_action(el, cx, cy)
end

--- Cycle focus across a provided ordered list of elements
---@param elements Element[]
---@param delta integer positive for next, negative for previous
function UIClass:cycle_focus(elements, delta)
  if not elements or #elements == 0 then
    return
  end

  local current = self.state.selected
  local idx = nil
  for i, e in ipairs(elements) do
    if e == current then
      idx = i
      break
    end
  end

  if not idx then
    idx = delta and delta < 0 and #elements or 1
  else
    local n = #elements
    local next_idx = ((idx - 1 + (delta >= 0 and 1 or -1)) % n) + 1
    idx = next_idx
  end

  self:focus_element(elements[idx])
end

---@param x_or_evt number | ui.components.UIMouseEvent
---@param y number?
---@return boolean
function UIClass:offscreen(x_or_evt, y)
  local win = Config.window_size
  if type(x_or_evt) == "number" then
    assert(y, "if you pass x as number then y must be number")
    return x_or_evt < 0 or y < 0 or x_or_evt > win.width or y > win.height
  end
  return x_or_evt.x < 0
    or x_or_evt.y < 0
    or x_or_evt.x > win.width
    or x_or_evt.y > win.height
end

function UIClass:_update_user_message(x, y)
  if self.state.user_message then
    if self.state.tickers._last_x ~= -1 then
      self.state.tickers.x = self.state.tickers.x
        + math.abs(x - self.state.tickers._last_x)
      self.state.tickers.y = self.state.tickers.y
        + math.abs(y - self.state.tickers._last_y)
    end
    self.state.tickers._last_x = x
    self.state.tickers._last_y = y

    if
      self.state.tickers.x + self.state.tickers.y
      > Config.ui.message.mouse_move_to_close
    then
      self:_remove_user_message()
    end
  end
end

--- @TODO change this to config once i remove all the love2d references from config
UI = UIClass.new(Config.window_size.width, Config.window_size.height)

return UIClass
