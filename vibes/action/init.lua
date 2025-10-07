---@class vibes.Action.Opts.Callbacks
---@field initialize fun(action:vibes.Action)
---@field listen fun(action:vibes.Action, next: fun(vibes.BaseAction))
---@field complete fun(action:vibes.Action)

---@class actions.BaseOpts
---@field on_cancel? fun(action: vibes.Action): nil
---@field on_success? fun(action: vibes.Action): nil
---@field on_complete? fun(action: vibes.Action): nil

---@class vibes.Action.Opts : actions.BaseOpts
---@field name string

---@class (exact) vibes.Action : vibes.Class
---@field new fun(opts: vibes.Action.Opts) : vibes.Action
---@field init fun(self: vibes.Action, opts: vibes.Action.Opts)
---@field _started boolean
---@field name string
---@field start fun(self: vibes.Action): ActionResult
---@field update fun(self: vibes.Action, dt: number): ActionResult
---@field finish fun(self: vibes.Action): ActionResult
---@field _on_cancel? fun(action: vibes.Action): nil
---@field _on_success? fun(action: vibes.Action): nil
---@field _on_complete? fun(action: vibes.Action): nil
---@field _resolved_result? ActionResult
---@field transfer_callbacks fun(self: vibes.Action, target_action: vibes.Action): vibes.Action
---@field resolve fun(self: vibes.Action, result: ActionResult): nil
local Action = class("vibes.Action", {
  abstract = {
    start = true,
    update = true,
    finish = true,
  },
})

---@param opts vibes.Action.Opts
function Action:init(opts)
  validate(opts, {
    name = "string",
    on_cancel = "function?",
    on_success = "function?",
    on_complete = "function?",
  })

  self._started = false
  self.name = opts.name
  self._on_cancel = opts.on_cancel
  self._on_success = opts.on_success
  self._on_complete = opts.on_complete
  self._resolved_result = nil
end

--- Transfer callbacks from this action to a target action, then clear them
--- This is useful when chaining actions and you want to pass callbacks along
---@param target_action vibes.Action The action to transfer callbacks to
---@return vibes.Action The target action with the callbacks transferred
function Action:transfer_callbacks(target_action)
  -- Transfer the callbacks to the target action
  if target_action._on_cancel or self._on_cancel then
    local old = target_action._on_cancel
    local new = self._on_cancel
    target_action._on_cancel = function()
      if old then
        old(target_action)
      end

      if new then
        new(target_action)
      end
    end
  end

  if target_action._on_success or self._on_success then
    local old = target_action._on_success
    local new = self._on_success
    target_action._on_success = function()
      if old then
        old(target_action)
      end

      if new then
        new(target_action)
      end
    end
  end

  if target_action._on_complete or self._on_complete then
    local old = target_action._on_complete
    local new = self._on_complete
    target_action._on_complete = function()
      if old then
        old(target_action)
      end

      if new then
        new(target_action)
      end
    end
  end

  -- Clear the callbacks so they don't get called on this action
  self._on_cancel = nil
  self._on_success = nil
  self._on_complete = nil

  return target_action
end

--- Resolve this action with a specific result
--- This allows external code to force an action to complete/cancel without custom state variables
---@param result ActionResult The result to resolve this action with
function Action:resolve(result)
  assert(result == ActionResult.COMPLETE or result == ActionResult.CANCEL)
  self._resolved_result = result
end

return Action
