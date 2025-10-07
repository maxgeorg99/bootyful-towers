local GameModes = require "vibes.enum.mode-name"
local TotalStatsElement = require "ui.components.stat.total-stats"

---@class vibes.GameOverMenu : vibes.BaseMode
---@field primary_theme_instance vibes.SoundInstance?
---@field world_map vibes.Texture
local GameOverMenu = {}

function GameOverMenu:enter()
  print "GameOverMenu:enter()"
  print "GameOverMenu:enter()"
  print "GameOverMenu:enter()"
  print "GameOverMenu:enter()"
  assert(false)
  UI:reset(Config.window_size.width, Config.window_size.height)

  self.total_stats = TotalStatsElement.new {
    on_main_menu = function() State.mode = GameModes.MAIN_MENU end,
    on_new_game = function() State.mode = GameModes.CHARACTER_SELECTION end,
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

  UI.root:append_child(self.total_stats)
end

function GameOverMenu:update(_) end
function GameOverMenu:draw() end
function GameOverMenu:exit() end

---@param key string
function GameOverMenu:keypressed(key) end

return require("vibes.base-mode").wrap(GameOverMenu)
