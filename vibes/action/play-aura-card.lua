local Action = require "vibes.action"
local GameFunctions = require "vibes.data.game-functions"

---@class actions.PlayCard.Opts : actions.BaseOpts
---@field card vibes.AuraCard

---@class actions.PlayCard : vibes.Action
---@field new fun(opts: actions.PlayCard.Opts): actions.PlayCard
---@field init fun(self: actions.PlayCard, opts: actions.PlayCard.Opts)
---@field card vibes.AuraCard
local PlayCard = class("actions.PlayCard", { super = Action })

---@param opts actions.PlayCard.Opts
---@return vibes.Action
function PlayCard:init(opts)
  validate(opts, { card = AuraCard })

  Action.init(self, {
    name = "PlayAuraCard",
    on_cancel = opts.on_cancel,
    on_success = opts.on_success,
    on_complete = opts.on_complete,
  })

  self.card = opts.card
end

function PlayCard:start()
  if not State:play_aura_card(self.card) then
    return ActionResult.CANCEL
  end

  return ActionResult.COMPLETE
end

function PlayCard:update() return ActionResult.COMPLETE end
function PlayCard:finish() end

return PlayCard
