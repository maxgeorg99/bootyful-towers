local Action = require "vibes.action"
local ButtonElement = require "ui.elements.button"
local GameModes = require "vibes.enum.mode-name"
local Overlay = require "ui.components.elements.overlay"
local TotalStatsElement = require "ui.components.stat.total-stats"

---@class actions.Gameover.Opts : actions.BaseOpts

---@class actions.Gameover : vibes.Action
---@field new fun(opts: actions.Gameover.Opts): actions.ClickOnTower
---@field init fun(self: actions.Gameover, opts: actions.ClickOnTower.Opts)
---@field mode vibes.GameMode
---@field overlay ui.element.Overlay
---@field menus layout.Layout[]
---@field center vibes.Position
local Gameover = class("actions.ClickOnTower", { super = Action })

local MENU_W = 490

local MENU_H = 340
local PADDING = 30
local MENU_BTN_W = MENU_W - (PADDING * 2)
local MENU_BTN_H = 80

---@param opts actions.Gameover.Opts
function Gameover:init(opts)
  validate(opts, { tower = "vibes.Tower" })

  Action.init(self, {
    name = "Gameover",
    on_cancel = opts.on_cancel,
    on_success = opts.on_success,
    on_complete = opts.on_complete,
  })

  self.center = Position.new(
    (Config.window_size.width / 2) - (MENU_W / 2),
    (Config.window_size.height / 2) - (MENU_H / 2)
  )

  self.mode = State:get_mode() --[[@as vibes.GameMode]]
  self.menus = {}
  self.overlay = Overlay.new {
    background = Colors.black:opacity(0.8),
    can_close = false,
    z = Z.OVERLAY,
  }
end

function Gameover:start()
  UI.root:append_child(self.overlay)
  self.overlay:open(function() end)
  UI.root:append_child(self:_init_main_menu())
  return ActionResult.ACTIVE
end

function Gameover:update() return ActionResult.ACTIVE end

function Gameover:finish() end

function Gameover:_init_main_menu()
  local stats = TotalStatsElement.new {
    z = Z.MAX,
    on_main_menu = function()
      RESET_STATE()
      ActionQueue:clear()
      State.mode = GameModes.MAIN_MENU
    end,
    on_new_game = function()
      RESET_STATE()
      ActionQueue:clear()
      State.mode = GameModes.CHARACTER_SELECTION
    end,
    stats = {
      {
        label = "Total Damage",
        value = State.stat_holder.total_damage_dealt,
        icon = IconType.DAMAGE,
      },
      {
        label = "Gold Spent",
        value = State.stat_holder.total_gold_spent,
        icon = IconType.GOLD,
      },
      {
        label = "Enemies Defeated",
        value = State.stat_holder.total_enemies_killed,
        icon = IconType.SKULL,
      },
      {
        label = "Critical Hits",
        value = State.stat_holder.total_critical_hits,
        icon = IconType.CHANCE,
      },
    },
  }

  return stats
end

function Gameover:_to_float(value) return (value - 1) / 9 end
function Gameover:_to_range(value)
  value = math.max(0, math.min(0, value))
  return value * 9 + 1
end
return Gameover
