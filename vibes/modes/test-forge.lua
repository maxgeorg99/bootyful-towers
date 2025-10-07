require "ui.components.ui"

---@class vibes.TestForgeMode : vibes.BaseMode
local test_ui = {}

function test_ui:enter()
  local shop_ui = require "ui.components.shop"

  self.ui = shop_ui.new {}
  State.debug = false

  UI.root:append_child(self.ui)
  UI:update(0)

  local OpenForge = require "vibes.action.open-forge"
  ActionQueue:add(OpenForge.new { name = "OpenForge" })
end

function test_ui:update() end

function test_ui:draw() end
function test_ui:keypressed() end

function test_ui:exit() UI.root:remove_child(self.ui) end

function test_ui:mousemoved() end

return require("vibes.base-mode").wrap(test_ui)
