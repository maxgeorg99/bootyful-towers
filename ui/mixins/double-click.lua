--- @class double_click.State
--- @field last_click_time number

--- @class mixin.DoubleClick : Element
-- Methods implemented by DoubleClick
--- @field click fun(self: mixin.DoubleClick): boolean
--- @field reset_double_click fun(self: mixin.DoubleClick): nil
--- @field _double_click_state double_click.State
--
-- Methods implemented by DoubleClick Classes
--- @field _double_click fun(self: mixin.DoubleClick, evt: ui.components.UIMouseEvent)

--- @param el Element Element to mutate in place.
local function create(el)
  ---@cast el mixin.DoubleClick

  -- NOTE on the NOTE: copied by prime from TJ's original code found in mixin.Drag
  -- NOTE: We are using `rawset` here to avoid the checks we have in element
  -- that ensure we do not create these functions. This is the only place we
  -- want to create them, and this way skips the __newindex check.

  ---@param evt ui.components.UIMouseEvent
  rawset(el, "click", function(self, evt)
    if self._click then
      self:_click(evt)
    end

    local now = math.floor(love.timer.getTime() * 1000)
    if
      now - self._double_click_state.last_click_time
      < Config.ui.double_click_duration
    then
      if self._double_click then
        self:_double_click(evt)
      end
      self:reset_double_click()
    else
      self._double_click_state.last_click_time = now
    end

    return UIAction.HANDLED
  end)

  rawset(
    el,
    "reset_double_click",
    function(self)
      self._double_click_state = {
        last_click_time = -100,
      }
    end
  )
end

--- @param el Element
local function init(el)
  ---@cast el mixin.DoubleClick

  el:reset_double_click()
end

return {
  init = init,
  create = create,
}
