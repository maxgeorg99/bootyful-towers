local Action = require "vibes.action"
local TrophyUI = require "ui.components.trophy"

---@class actions.TrophySelection.Opts : actions.BaseOpts
---@field current_completed_wave number
---@field on_choose_shop fun(): nil

---@class actions.TrophySelection : vibes.Action
---@field new fun(opts: actions.TrophySelection.Opts): actions.TrophySelection
---@field init fun(self: actions.TrophySelection, opts: actions.TrophySelection.Opts)
---@field ui components.trophy.UI?
---@field current_completed_wave number
---@field on_complete fun(): nil
---@field on_choose_shop fun(): nil
local TrophySelection = class("actions.TrophySelection", { super = Action })

---@param opts actions.TrophySelection.Opts
function TrophySelection:init(opts)
  validate(opts, {
    current_completed_wave = "number",
    on_choose_shop = "function?",
  })

  self.completed = false
  self.current_completed_wave = opts.current_completed_wave
  self.on_choose_shop = opts.on_choose_shop

  Action.init(self, {
    name = "TrophySelection",
    on_cancel = opts.on_cancel,
    on_success = opts.on_success,
    on_complete = opts.on_complete,
  })
end

function TrophySelection:start()
  logger.info "TrophySelection:start"

  self.ui = TrophyUI.new {
    on_complete = function() self:resolve(ActionResult.COMPLETE) end,
    current_completed_wave = self.current_completed_wave,
    on_choose_shop = self.on_choose_shop,
  }
  UI.root:append_child(self.ui)

  return ActionResult.ACTIVE
end

function TrophySelection:update()
  if self.completed then
    return ActionResult.COMPLETE
  end
  return ActionResult.ACTIVE
end

function TrophySelection:finish()
  logger.info "TrophySelection:finish"

  if not self.ui then
    logger.warn "TrophySelection:finish: no ui?"
    return
  end

  UI.root:remove_child(self.ui)
  self.ui = nil

  -- Note: We don't restore previous_lifecycle here because the on_complete callback
  -- will handle setting the next lifecycle phase (PLAYER_PREP)
end

return TrophySelection
