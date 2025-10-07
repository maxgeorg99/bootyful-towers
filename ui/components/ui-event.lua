local _id = 0
local function get_next_id()
  _id = _id + 1
  return _id
end

---@class ui.components.UIEvent
---@field type string
---@field id number|string

---@class ui.components.UIMouseEvent : ui.components.UIEvent
---@field x number
---@field y number
---@field target Element

---@class ui.components.UIClickEvent : ui.components.UIMouseEvent
---@field type "click"

---@class ui.components.UIPressedEvent : ui.components.UIMouseEvent
---@field type "pressed"

---@class ui.components.UIReleasedEvent : ui.components.UIMouseEvent
---@field type "released"

---@class ui.components.UIDragStartEvent : ui.components.UIMouseEvent
---@field type "drag_start"

---@class ui.components.UIDragEvent : ui.components.UIMouseEvent
---@field type "drag"

---@class ui.components.UIDragEndEvent : ui.components.UIMouseEvent
---@field type "drag_end"

---@class ui.components.UIMouseMovedEvent : ui.components.UIMouseEvent
---@field type "mouse"

---@class ui.components.UIFocusEvent : ui.components.UIMouseEvent
---@field type "focus"

---@class ui.components.UIBlurEvent : ui.components.UIMouseEvent
---@field type "blur"

return {
  ---@param el Element
  ---@param x number
  ---@param y number
  ---@return ui.components.UIDragEvent
  drag = function(el, x, y)
    return {
      id = get_next_id(),
      x = x,
      y = y,
      type = "drag",
      target = el,
    }
  end,

  ---@param el Element
  ---@param x number
  ---@param y number
  ---@return ui.components.UIDragEndEvent
  drag_end = function(el, x, y)
    return {
      id = get_next_id(),
      x = x,
      y = y,
      target = el,
      type = "drag_end",
    }
  end,

  ---@param el Element
  ---@param x number
  ---@param y number
  ---@return ui.components.UIDragStartEvent
  drag_start = function(el, x, y)
    return {
      id = get_next_id(),
      x = x,
      y = y,
      target = el,
      type = "drag_start",
    }
  end,

  ---@param el Element
  ---@param x number
  ---@param y number
  ---@return ui.components.UIPressedEvent
  pressed = function(el, x, y)
    return {
      id = get_next_id(),
      x = x,
      y = y,
      target = el,
      type = "pressed",
    }
  end,

  ---@param el Element
  ---@param x number
  ---@param y number
  ---@return ui.components.UIMouseEvent
  mouse = function(el, x, y)
    return {
      id = get_next_id(),
      x = x,
      y = y,
      target = el,
      type = "mouse",
    }
  end,

  ---@param el Element
  ---@param x number
  ---@param y number
  ---@return ui.components.UIReleasedEvent
  released = function(el, x, y)
    return {
      id = get_next_id(),
      x = x,
      y = y,
      target = el,
      type = "released",
    }
  end,

  ---@param el Element
  ---@param x number
  ---@param y number
  ---@return ui.components.UIFocusEvent
  focus = function(el, x, y)
    return {
      id = get_next_id(),
      x = x,
      y = y,
      target = el,
      type = "focus",
    }
  end,

  ---@param el Element
  ---@param x number
  ---@param y number
  ---@return ui.components.UIBlurEvent
  blur = function(el, x, y)
    return {
      id = get_next_id(),
      x = x,
      y = y,
      target = el,
      type = "blur",
    }
  end,

  ---@param el Element
  ---@param x number
  ---@param y number
  ---@return ui.components.UIClickEvent
  click = function(el, x, y)
    return {
      id = get_next_id(),
      x = x,
      y = y,
      target = el,
      type = "click",
    }
  end,
}
