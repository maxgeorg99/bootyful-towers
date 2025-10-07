local Action = require "vibes.action"
local PlacedTower = require "ui.components.tower.placed-tower"

local PlayAuraCard = require "vibes.action.play-aura-card"
local PlayEnhancementCard = require "vibes.action.play-enhancement-card"
local PlayTowerCard = require "vibes.action.play-tower-card"

---@class actions.TryPlayCard.Opts : actions.BaseOpts
---@field card vibes.Card
---@field target? Element

---@class actions.TryPlayCard : vibes.Action
---@field new fun(opts: actions.TryPlayCard.Opts): actions.TryPlayCard
---@field init fun(self: actions.TryPlayCard, opts: actions.TryPlayCard.Opts)
---@field card vibes.Card
---@field target? Element
local TryPlayCard = class("actions.TryPlayCard", { super = Action })

---@param opts actions.TryPlayCard.Opts
function TryPlayCard:init(opts)
  validate(opts, {
    card = Card,
    target = Optional { PlacedTower },
  })

  Action.init(self, {
    name = "TryPlayCard",
    on_cancel = opts.on_cancel,
    on_success = opts.on_success,
    on_complete = opts.on_complete,
  })

  self.card = opts.card
  self.target = opts.target
end

function TryPlayCard:start()
  local energy_cost = State:get_modified_energy_cost(self.card)
  if State.player.energy < energy_cost then
    UI:create_user_message "Not enough energy"
    return ActionResult.CANCEL
  end

  local tower_card = self.card:get_tower_card()
  if tower_card then
    ActionQueue:add(self:transfer_callbacks(PlayTowerCard.new {
      card = tower_card,
      target = self.target,
    }))
    self:resolve(ActionResult.COMPLETE)
    return ActionResult.COMPLETE
  end

  local enhancement = self.card:get_enhancement_card()
  if enhancement then
    if not self.target then
      UI:create_user_message "You must select a tower to enhance"
      self:resolve(ActionResult.CANCEL)
      return ActionResult.CANCEL
    end

    local target = require("ui.components.tower.placed-tower").is(self.target)

    if target then
      ActionQueue:add(self:transfer_callbacks(PlayEnhancementCard.new {
        card = enhancement,
        target = target,
      }))
      self:resolve(ActionResult.COMPLETE)
      return ActionResult.COMPLETE
    else
      self:resolve(ActionResult.COMPLETE)
      return ActionResult.CANCEL
    end
  end

  local aura = self.card:get_aura_card()
  if aura then
    ActionQueue:add(self:transfer_callbacks(PlayAuraCard.new {
      card = aura,
    }))

    self:resolve(ActionResult.COMPLETE)
    return ActionResult.COMPLETE
  end

  error "unhandled card type"
end

function TryPlayCard:update() return ActionResult.ACTIVE end
function TryPlayCard:finish() end

return TryPlayCard
