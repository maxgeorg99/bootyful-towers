local Action = require "vibes.action"

---@class actions.CardSelection.Opts : actions.BaseOpts
---@field rarity Rarity?
---@field is_trophy boolean?

---@class actions.CardSelection : vibes.Action
---@field new fun(opts: actions.CardSelection.Opts): actions.CardSelection
---@field init fun(self: actions.CardSelection, opts: actions.CardSelection.Opts)
---@field ui components.trophy.CardsTrophyUI?
---@field previous_lifecycle RoundLifecycle
---@field rarity Rarity?
---@field is_trophy boolean?
local CardSelection = class("actions.CardSelection", { super = Action })

---@param opts actions.CardSelection.Opts
function CardSelection:init(opts)
  validate(opts, {
    rarity = "Rarity?",
    is_trophy = "boolean?",
  })

  Action.init(self, {
    name = "CardSelection",
    on_cancel = opts.on_cancel,
    on_success = opts.on_success,
    on_complete = opts.on_complete,
  })

  self.previous_lifecycle = GAME.lifecycle
  self.rarity = opts.rarity
  self.is_trophy = opts.is_trophy
  self._finished = false
end

function CardSelection:start()
  logger.info "CardSelection:start"

  GAME.lifecycle = RoundLifecycle.CARD_SELECTION

  local CardTrophyUI = require "ui.components.trophy.cards-trophy"

  self.ui = CardTrophyUI.new {
    on_complete = function()
      self._finished = true
      self:resolve(ActionResult.COMPLETE)
    end,
    rarity = self.rarity,
    is_trophy = self.is_trophy,
  }

  UI.root:append_child(self.ui)

  return ActionResult.ACTIVE
end

function CardSelection:update()
  if self._finished then
    return ActionResult.COMPLETE
  end
  return ActionResult.ACTIVE
end

function CardSelection:finish()
  logger.info "CardSelection:finish"

  if not self.ui then
    logger.warn "CardSelection:finish: no ui?"
    return
  end

  UI.root:remove_child(self.ui)
  self.ui = nil

  -- Note: We don't restore previous_lifecycle here because the on_complete callback
  -- will handle setting the next lifecycle phase (PLAYER_PREP)
end

return CardSelection
