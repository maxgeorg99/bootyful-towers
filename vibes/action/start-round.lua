local Action = require "vibes.action"

---@class actions.StartRound.Opts : actions.BaseOpts

---@class actions.StartRound : vibes.Action
---@field new fun(opts: actions.StartRound.Opts): actions.StartRound
---@field init fun(self: actions.StartRound, opts: actions.StartRound.Opts)
local StartRound = class("actions.StartRound", { super = Action })

---@param opts actions.StartRound.Opts
function StartRound:init(opts)
  Action.init(self, {
    name = "StartRound",
    on_cancel = opts.on_cancel,
    on_success = opts.on_success,
    on_complete = opts.on_complete,
  })
end

function StartRound:start()
  if State.mode ~= ModeName.GAME then
    return ActionResult.CANCEL
  end

  local mode = State:get_mode() --[[@as vibes.GameMode]]
  mode.lifecycle = RoundLifecycle.ENEMIES_SPAWN_START

  return ActionResult.COMPLETE
end

function StartRound:update() return ActionResult.COMPLETE end
function StartRound:finish() return ActionResult.COMPLETE end

return StartRound
