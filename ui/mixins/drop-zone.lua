--- @class drop_zone.State
--- @field active_element Element? The element currently being considered for drop zones
--- @field status DropzoneStatus Current status of the drop zone element

--- @class mixin.DropZone : Element
---
-- Methods implemented by DropZone, Do not override these directly!
--- @field dropzone_accepts_element fun(self: mixin.DropZone, element: Element): boolean
--- @field dropzone_on_start fun(self: mixin.DropZone, element: Element): UIAction? Called when a drag starts and drop zones are active
--- @field dropzone_on_drop fun(self: mixin.DropZone, element: Element): UIAction? Called when an element is dropped on the drop zone
--- @field dropzone_on_finish fun(self: mixin.DropZone, element: Element): UIAction? Called when a drag finishes and drop zones are not active
--- @field dropzone_active_element fun(self: mixin.DropZone): Element? Whether the current Element has an active droppable element.
--- @field dropzone_is_hovering fun(self: mixin.DropZone): boolean Whether the current Element has a droppable element hovering over it.
--- @field dropzone_is_accepting fun(self: mixin.DropZone): boolean Whether the current Element has a droppable element accepting an element.
--- @field dropzone_is_rejected fun(self: mixin.DropZone): boolean Whether the current Element has a droppable element rejecting an element.
--- @field _dropzone_state drop_zone.State Private state for the drop zone, should not be used.
--
-- Methods implemented by DropZone Classes (provides capabilities to be overridden)
--- @field _dropzone_accepts_element fun(self: mixin.DropZone, element: Element): boolean
--- @field _dropzone_on_start fun(self: mixin.DropZone, element: Element): UIAction?
--- @field _dropzone_on_finish fun(self: mixin.DropZone, element: Element): UIAction?
--- @field _dropzone_on_drop fun(self: mixin.DropZone, element: Element): UIAction?

--- @param el Element Element to mutate in place.
local function create(el)
  ---@cast el mixin.DropZone

  function el:dropzone_accepts_element(element)
    if not self._dropzone_state then
      return false
    end

    return self:_dropzone_accepts_element(element)
  end

  ---@param self mixin.DropZone
  ---@return Element?
  function el:dropzone_active_element()
    return self._dropzone_state and self._dropzone_state.active_element
  end

  ---@param self mixin.DropZone
  function el:dropzone_is_hovering()
    return self._dropzone_state
      and self._dropzone_state.active_element ~= nil
      and self._dropzone_state.status == DropzoneStatus.HOVERING
  end

  function el:dropzone_is_accepting()
    return self._dropzone_state
      and self._dropzone_state.active_element ~= nil
      and self._dropzone_state.status == DropzoneStatus.ACCEPTING
  end

  function el:dropzone_is_rejected()
    return self._dropzone_state
      and self._dropzone_state.active_element ~= nil
      and self._dropzone_state.status == DropzoneStatus.REJECTED
  end

  ---@param self mixin.DropZone
  ---@param element Element
  function el:dropzone_on_start(element)
    if not self._dropzone_state then
      return
    end

    local state = self._dropzone_state
    state.active_element = element

    if not self:dropzone_accepts_element(element) then
      state.status = DropzoneStatus.REJECTED
      return
    end

    state.status = DropzoneStatus.ACCEPTING

    if self._dropzone_on_start then
      return self:_dropzone_on_start(element)
    end

    return UIAction.HANDLED
  end

  ---@param self mixin.DropZone
  ---@param element Element
  function el:dropzone_on_finish(element)
    if not self._dropzone_state then
      print "dropzone_on_finish: not active"
      return
    end

    local state = self._dropzone_state
    state.status = DropzoneStatus.INACTIVE
    state.active_element = nil

    if self._dropzone_on_finish then
      return self:_dropzone_on_finish(element)
    end

    return UIAction.HANDLED
  end

  ---@param self mixin.DropZone
  ---@param element Element
  function el:dropzone_on_drop(element)
    if not self._dropzone_state then
      return
    end

    -- Should not be able to get here without this dropzone accepting the element.
    assert(self:dropzone_accepts_element(element))

    -- Not sure if this one makes sense or not, but it's probably worth checking for now
    assert(self:dropzone_is_hovering())

    local result = self:_dropzone_on_drop(element)

    -- Reset hovering state
    self._dropzone_state.status = DropzoneStatus.INACTIVE
    self._dropzone_state.active_element = nil

    return result or UIAction.HANDLED
  end
end

--- @param el Element
local function init(el)
  ---@cast el mixin.DropZone

  validate(el, {
    _dropzone_accepts_element = "function",
    _dropzone_on_drop = "function",
  })

  el._dropzone_state = {
    active_element = nil,
    status = DropzoneStatus.INACTIVE,
  }

  table.insert(el._post_update_hooks, function()
    local active_element = el:dropzone_active_element()
    if active_element then
      if not el:dropzone_accepts_element(active_element) then
        el._dropzone_state.status = DropzoneStatus.REJECTED
        return
      end

      local box = el:get_box()
      if box:contains(State.mouse.x, State.mouse.y) then
        el._dropzone_state.status = DropzoneStatus.HOVERING
      else
        el._dropzone_state.status = DropzoneStatus.ACCEPTING
      end
    else
      el._dropzone_state.status = DropzoneStatus.INACTIVE
    end
  end)
end

--- Check if an element is a drop zone
--- @param el any
--- @return boolean
local function is(el) return type(el) == "table" and el._dropzone_state ~= nil end

return {
  init = init,
  create = create,
  is = is,
}
