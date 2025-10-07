require "ui.components.ui"
local TotalStatsElement = require "ui.components.stat.total-stats"

---@class vibes.TestUI : vibes.BaseMode
---@field total_stats_element ui.components.TotalStatsElement?
local test_ui = {
  total_stats_element = nil,
}

function test_ui:enter()
  -- Ensure UI is properly initialized for this mode
  UI:reset(Config.window_size.width, Config.window_size.height)

  -- Create the TotalStatsElement (1/3 width, 2/3 height, centered)
  self:_create_total_stats()
end

--- Create the TotalStatsElement
function test_ui:_create_total_stats()
  -- Create 3 fake stats
  local fake_stats = {
    {
      label = "Total Damage",
      value = 12450,
      icon = IconType.DAMAGE,
    },
    {
      label = "Gold Earned",
      value = 9876,
      icon = IconType.GOLD,
    },
    {
      label = "Enemies Defeated",
      value = 543,
      icon = IconType.SKULL,
    },
  }

  self.total_stats_element = TotalStatsElement.new {
    stats = fake_stats,
    on_main_menu = function() print "Main Menu" end,
    on_new_game = function() print "New Game" end,
  }
  self.total_stats_element:set_debug(true)

  UI.root:append_child(self.total_stats_element)
  UI:debug_print_ui()
end

function test_ui:update(dt) UI:update(dt) end

function test_ui:draw(dt) end

function test_ui:keypressed(key)
  if key == "escape" then
    -- Exit test mode
    love.event.quit()
  end
end

function test_ui:exit() end

function test_ui:mousemoved(x, y) UI:mousemoved(x, y) end

function test_ui:mousepressed(x, y, button) UI:mousepressed(button, x, y) end

function test_ui:mousereleased(x, y, button) UI:mousereleased(button, x, y) end

return require("vibes.base-mode").wrap(test_ui)
