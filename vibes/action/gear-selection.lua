local Action = require "vibes.action"

---@class actions.GearSelection.Opts : actions.BaseOpts

---@class actions.GearSelection : vibes.Action
---@field new fun(opts: actions.GearSelection.Opts): actions.GearSelection
---@field init fun(self: actions.GearSelection, opts: actions.GearSelection.Opts)
---@field ui components.trophy.GearTrophyUI?
---@field previous_lifecycle RoundLifecycle
local GearSelection = class("actions.GearSelection", { super = Action })

---@param opts actions.GearSelection.Opts
function GearSelection:init(opts)
  validate(opts, {})

  Action.init(self, {
    name = "GearSelection",
    on_cancel = opts.on_cancel,
    on_success = opts.on_success,
    on_complete = opts.on_complete,
  })

  self.previous_lifecycle = GAME.lifecycle
end

function GearSelection:start()
  logger.info "GearSelection:start"
  GAME.lifecycle = RoundLifecycle.GEAR_SELECTION

  local GearTrophyUI = require "ui.components.trophy.gear-trophy"
  self.ui = GearTrophyUI.new {
    on_complete = function() self:resolve(ActionResult.COMPLETE) end,
  }

  UI.root:append_child(self.ui)

  return ActionResult.ACTIVE
end

function GearSelection:update() return ActionResult.ACTIVE end

function GearSelection:finish()
  logger.info "GearSelection:finish"

  if not self.ui then
    logger.warn "GearSelection:finish: no ui?"
    return
  end

  UI.root:remove_child(self.ui)
  self.ui = nil

  -- Note: We don't restore previous_lifecycle here because the on_complete callback
  -- will handle setting the next lifecycle phase (PLAYER_PREP)
end

return GearSelection
