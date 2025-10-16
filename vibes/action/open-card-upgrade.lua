local Action = require "vibes.action"

---@class actions.OpenCardUpgrade.Opts : actions.BaseOpts

---@class actions.OpenCardUpgrade : vibes.Action
---@field upgrade_ui components.CardUpgradeUI?
---@field gold_spent boolean
local OpenCardUpgrade = class("actions.OpenCardUpgrade", { super = Action })

---@param opts actions.OpenCardUpgrade.Opts
function OpenCardUpgrade:init(opts)
  opts = opts or {}
  Action.init(self, {
    name = "OpenCardUpgrade",
    on_cancel = opts.on_cancel,
    on_success = opts.on_success,
    on_complete = opts.on_complete,
  })
  self.gold_spent = false
end

function OpenCardUpgrade:start()
  -- Check if player has enough gold
  if State.player.gold < 100 then
    logger.info("Player cannot afford card upgrade (needs 100 gold)")
    return ActionResult.CANCEL
  end

  -- Deduct gold
  State.player:use_gold(100)
  self.gold_spent = true

  -- Create card upgrade UI
  local CardUpgradeUI = require "ui.components.card-upgrade"
  self.upgrade_ui = CardUpgradeUI.new {
    on_complete = function()
      self:resolve(ActionResult.COMPLETE)
    end,
    on_cancel = function()
      -- Refund the gold if cancelled
      State.player:add_gold(100)
      self.gold_spent = false
      self:resolve(ActionResult.CANCEL)
    end,
  }
  UI.root:append_child(self.upgrade_ui)

  return ActionResult.ACTIVE
end

function OpenCardUpgrade:update()
  -- Handle escape key to close upgrade UI
  if love.keyboard.isDown "escape" then
    -- Refund gold if it was spent
    if self.gold_spent then
      State.player:add_gold(100)
      self.gold_spent = false
    end
    self:resolve(ActionResult.CANCEL)
    return ActionResult.COMPLETE
  end

  return ActionResult.ACTIVE
end

function OpenCardUpgrade:finish()
  if self.upgrade_ui then
    UI.root:remove_child(self.upgrade_ui)
  end
end

return OpenCardUpgrade
