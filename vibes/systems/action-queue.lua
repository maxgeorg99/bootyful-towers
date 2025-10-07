--[[

ACTION SYSTEM DOCUMENTATION

The action system provides a queue-based way to manage sequential game operations
with support for callbacks, external resolution, and action chaining.

=== BASIC USAGE ===

1. Create an action:
   local action = SomeAction.new { param = value }

2. Add to queue:
   ActionQueue:add(action)  -- Add to back
   ActionQueue:push(action) -- Add to front

3. The queue automatically processes actions in order

=== ACTION LIFECYCLE ===

1. action:start() - Called once when action begins
2. action:update(dt) - Called every frame while active
3. action:finish() - Called when action completes/cancels
4. Callbacks are called automatically by the queue

=== CALLBACKS ===

Actions support three callback types:

local action = SomeAction.new {
  on_cancel = function(action) print("Action was cancelled") end,
  on_success = function(action) print("Action completed successfully") end,
  on_complete = function(action) print("Action finished (always called)") end,
}

=== EXTERNAL RESOLUTION ===

You can resolve any action from external code:

-- Force completion
action:resolve(ActionResult.COMPLETE)

-- Force cancellation  
action:resolve(ActionResult.CANCEL)

-- Example: UI callback
GAME.ui:animate_something({
  on_complete = function() my_action:resolve(ActionResult.COMPLETE) end
})

=== ACTION CHAINING ===

Transfer callbacks from one action to another:

local next_action = NextAction.new { param = value }
self:transfer_callbacks(next_action)
ActionQueue:add(next_action)

-- Or more concisely:
ActionQueue:add(self:transfer_callbacks(NextAction.new { param = value }))

=== CREATING CUSTOM ACTIONS ===

local MyAction = class("MyAction", { super = Action })

function MyAction:init(opts)
  Action.init(self, {
    name = "MyAction",
    on_cancel = opts.on_cancel,
    on_success = opts.on_success,
    on_complete = opts.on_complete,
  })
  -- Your custom fields here
end

function MyAction:start()
  -- Setup logic here
  return ActionResult.ACTIVE  -- or COMPLETE/CANCEL
end

function MyAction:update(dt)
  -- Frame-by-frame logic here
  -- Use self:resolve(result) for external completion
  return ActionResult.ACTIVE  -- or COMPLETE/CANCEL
end

function MyAction:finish()
  -- Cleanup logic here
end

=== ACTION RESULTS ===

- ActionResult.ACTIVE: Continue running (default)
- ActionResult.COMPLETE: Action succeeded
- ActionResult.CANCEL: Action was cancelled/failed

--]]

---@class vibes.ActionQueue
---@field new fun() : vibes.ActionQueue
---@field init fun(self: vibes.ActionQueue)
---@field items vibes.Action[]
local ActionQueue = class "vibes.ActionQueue"

function ActionQueue:init() self.items = {} end
function ActionQueue:clear() self.items = {} end

--- Adds an action to the end of the queue
---@param action vibes.Action
function ActionQueue:add(action)
  logger.debug(
    "ActionQueue:add to back(%d at %f): %s",
    #self.items,
    love.timer.getTime(),
    action.name
  )
  table.insert(self.items, action)
end

--- Push an action to the front of the queue
function ActionQueue:push(action)
  logger.debug(
    "ActionQueue:push to front(%d at %f): %s",
    #self.items,
    love.timer.getTime(),
    action.name
  )
  table.insert(self.items, 1, action)
end

---@param result ActionResult
local should_result_complete = function(result)
  return result == ActionResult.CANCEL or result == ActionResult.COMPLETE
end

---@param dt number
function ActionQueue:update(dt)
  logger.trace("ActionQueue:update: %s (%s)", #self.items, self.items[1])
  local action = self.items[1]
  if not action then
    return
  end

  if not action._started then
    action._started = true
    logger.debug(
      "ActionQueue:start: performing action: %s at %f",
      action.name,
      love.timer.getTime()
    )

    local result = action:start()
    assert(ActionResult[result], "invalid action result: " .. tostring(result))

    if should_result_complete(result) then
      return self:_complete_action(result, action)
    elseif result == ActionResult.ACTIVE then
      return
    end
  end

  -- Check if action has been resolved externally first
  local result = action._resolved_result
    or action:update(dt)
    or ActionResult.ACTIVE

  assert(ActionResult[result], "invalid action result: " .. tostring(result))
  if should_result_complete(result) then
    return self:_complete_action(result, action)
  end
end

---@param action vibes.Action
function ActionQueue:_complete_action(result, action)
  if result == ActionResult.CANCEL then
    if action._on_cancel then
      action:_on_cancel()
    end
  elseif result == ActionResult.COMPLETE then
    if action._on_success then
      action:_on_success()
    end
  end

  -- Always call on_complete before finish (like a finally block)
  if action._on_complete then
    action:_on_complete()
  end

  logger.info("ActionQueue:complete: %s", action.name)
  action:finish()
  table.remove(self.items, 1)
end

return ActionQueue.new()
