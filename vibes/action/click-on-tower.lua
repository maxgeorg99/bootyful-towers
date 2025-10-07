local Action = require "vibes.action"
local CardSlots = require "ui.components.tower.elements.card-slots"
local Overlay = require "ui.components.elements.overlay"
local TowerOverview = require "ui.components.tower.overview"

---@class actions.ClickOnTower.Opts : actions.BaseOpts
---@field tower components.PlacedTower

---@class actions.ClickOnTower : vibes.Action
---@field new fun(opts: actions.ClickOnTower.Opts): actions.ClickOnTower
---@field init fun(self: actions.ClickOnTower, opts: actions.ClickOnTower.Opts)
---@field mode vibes.GameMode
---@field tower components.PlacedTower
---@field overlay ui.element.Overlay
---@field tower_overview components.TowerOverview
---@field card_slots components.TowerCardSlots
local ClickOnTower = class("actions.ClickOnTower", { super = Action })

---@param opts actions.ClickOnTower.Opts
function ClickOnTower:init(opts)
  validate(opts, { tower = "vibes.Tower" })

  Action.init(self, {
    name = "ClickOnTower",
    on_cancel = opts.on_cancel,
    on_success = opts.on_success,
    on_complete = opts.on_complete,
  })

  self.tower = opts.tower

  self.mode = State:get_mode() --[[@as vibes.GameMode]]

  self.overlay = Overlay.new {
    background = Colors.black:opacity(0.9),
    on_close = function()
      self.overlay:close()
      self:resolve(ActionResult.COMPLETE)
    end,
  }

  self.tower_overview = TowerOverview.new {
    card = self.tower.card,
  }

  self.tower_overview:set_opacity(0)

  self.card_slots = CardSlots.new {
    box = Box.new(
      Position.new(0, self.tower_overview:get_height() + 20),
      Config.window_size.width,
      150
    ),
    placed_tower = self.tower,
  }

  self.card_slots:set_opacity(0)
end

function ClickOnTower:start()
  GAME.ui.hand:animate_style({ opacity = 0 }, { duration = 0.3 })

  UI.root:append_child(self.overlay)
  UI.root:append_child(self.tower_overview)
  UI.root:append_child(self.card_slots)
  self.tower_overview:animate_style({ opacity = 1 }, {
    duration = 0.3,
    on_complete = function()
      self.card_slots:set_hidden(false)
      self.card_slots:animate_style({ opacity = 1 }, { duration = 0.5 })
    end,
  })
  self.overlay:open()
  return ActionResult.ACTIVE
end

function ClickOnTower:update() return ActionResult.ACTIVE end

function ClickOnTower:finish()
  GAME.ui.hand:animate_style({ opacity = 1 }, { duration = 0.3 })

  self.overlay:close()
  self.card_slots:animate_style({ opacity = 0 }, { duration = 0.3 })
  self.tower_overview:animate_style({ opacity = 0 }, {
    duration = 0.3,
    on_complete = function()
      UI.root:remove_child(self.tower_overview)
      UI.root:remove_child(self.overlay)
      UI.root:remove_child(self.card_slots)
    end,
  })
end

return ClickOnTower
