local EnemyViewer = require "ui.components.enemy-viewer"

--- @class (exact) vibes.TestEnemyViewer : vibes.BaseMode
local test_enemy_viewer = {}

function test_enemy_viewer:enter()
  print "[DEBUG] test_enemy_viewer:enter() - Creating enemy viewer"
  local viewer = EnemyViewer.new()
  print "[DEBUG] test_enemy_viewer:enter() - Enemy viewer created, adding to UI.root"
  UI.root:append_child(viewer)
  print "[DEBUG] test_enemy_viewer:enter() - Enemy viewer added to UI.root"
end

function test_enemy_viewer:update(dt)
  -- Let the enemy viewer handle its own updates
end

function test_enemy_viewer:draw() love.graphics.clear(0.2, 0.2, 0.2) end

function test_enemy_viewer:keypressed(key)
  if key == "escape" then
    State.mode = require("vibes.enum.mode-name").MAIN_MENU
  end
end

return require("vibes.base-mode").wrap(test_enemy_viewer)
