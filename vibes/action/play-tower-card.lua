local Action = require "vibes.action"
local GameFunctions = require "vibes.data.game-functions"
local game = require "utils.user-interaction"

local PendingTower = require "ui.components.tower.pending-tower"
local TowerCard = require "vibes.card.base-tower-card"

---@class actions.PlayTowerCard.Opts : actions.BaseOpts
---@field card vibes.TowerCard
---@field target? Element

---@class actions.PlayTowerCard : vibes.Action
---@field new fun(opts: actions.PlayTowerCard.Opts): actions.PlayTowerCard
---@field init fun(self: self, opts: actions.PlayTowerCard.Opts)
---@field card vibes.TowerCard
---@field target? Element
---@field mode vibes.GameMode
---@field init_at number
---@field pending_tower_ui? components.PendingTower
local PlayTowerCard = class("actions.PlayTowerCard", { super = Action })

---@param opts actions.PlayTowerCard.Opts
function PlayTowerCard:init(opts)
  validate(opts, { card = TowerCard })

  Action.init(self, {
    name = "BeginTowerPlacement",
    on_cancel = opts.on_cancel,
    on_success = opts.on_success,
    on_complete = opts.on_complete,
  })

  self.card = opts.card
  self.target = opts.target
  self.init_at = os.time()
end

function PlayTowerCard:start()
  -- TODO: This should be an action? Possibly inserted at start? Idk. Animation
  -- system maybe could do it instead.
  GAME.ui:set_interactable(false)

  local tower_card = self.card:get_tower_card()
  if tower_card then
    self.pending_tower_ui = PendingTower.new {
      tower = tower_card.tower,
      on_place = function(cell)
        if not tower_card.tower:can_place(cell) then
          return false
        end

        local success = State:play_tower_card {
          tower_card = tower_card,
          cell = cell,
        }

        if success then
          self:resolve(ActionResult.COMPLETE)
        end
        return success
      end,
      on_cancel = function()
        self:resolve(ActionResult.CANCEL)
        return nil
      end,
    }

    -- Add to UI root so it renders on top
    UI.root:append_child(self.pending_tower_ui)
  else
    return ActionResult.CANCEL
  end

  return ActionResult.ACTIVE
end

function PlayTowerCard:update()
  -- The UI component handles all the interaction logic now
  -- This action will be resolved by the UI component callbacks
  return ActionResult.ACTIVE
end

function PlayTowerCard:finish()
  GAME.ui:set_interactable(true)

  EventBus:emit_card_played { card = self.card }

  -- Clean up the UI component if it still exists
  if self.pending_tower_ui then
    self.pending_tower_ui:remove_from_parent()
    self.pending_tower_ui = nil
  end
end

return PlayTowerCard
