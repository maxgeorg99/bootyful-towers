local GameFunctions = require "vibes.data.game-functions"

local Action = require "vibes.action"

---@class actions.PlayEnhancementCard.Opts : actions.BaseOpts
---@field card vibes.EnhancementCard
---@field target components.PlacedTower

---@class actions.PlayEnhancementCard : vibes.Action
---@field new fun(opts: actions.PlayEnhancementCard.Opts): actions.PlayEnhancementCard
---@field init fun(self: self, opts: actions.PlayEnhancementCard.Opts)
---@field card vibes.EnhancementCard
---@field target components.PlacedTower
local PlayEnhancementCard =
  class("actions.PlayEnhancementCard", { super = Action })

---@param opts actions.PlayEnhancementCard.Opts
function PlayEnhancementCard:init(opts)
  local PlacedTower = require "ui.components.tower.placed-tower"

  validate(opts, {
    card = EnhancementCard,
    target = PlacedTower,
  })

  Action.init(self, {
    name = "PlayEnhancementCard",
    on_cancel = opts.on_cancel,
    on_success = opts.on_success,
    on_complete = opts.on_complete,
  })

  self.card = opts.card
  self.target = opts.target
end

function PlayEnhancementCard:start()
  if not State:play_enhancement_card(self.card, self.target) then
    return ActionResult.CANCEL
  end

  return ActionResult.COMPLETE
end

function PlayEnhancementCard:update() return ActionResult.COMPLETE end
function PlayEnhancementCard:finish() end

return PlayEnhancementCard
