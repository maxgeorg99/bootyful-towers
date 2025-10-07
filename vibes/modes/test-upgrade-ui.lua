require "ui.components.ui"

local UIRootElement = require "ui.components.ui-root-element"

---@class vibes.TestUpgradeUI : vibes.BaseMode
local test_ui = {
  name = "test_upgrade_ui",
}

function test_ui:update(dt) UI:update(dt) end

function test_ui:draw() end

function test_ui:keypressed() end
function test_ui:enter()
  local ui = UIRootElement.new()

  -- ui:append_child(tower_ui)

  UI.root:append_child(ui)

  self.ui = ui

  State.player.energy = 3

  UI:debug_print_ui()
end

function test_ui:exit()
  UI:debug_print_ui()
  UI.root:remove_child(self.ui)
end

function test_ui:mousemoved() end

return require("vibes.base-mode").wrap(test_ui)
