require "ui.components.ui"
local ButtonElement = require "ui.elements.button"

---@class vibes.TextInventoryMode : vibes.BaseMode
local test_ui = {}

function test_ui:enter()
  State.gear_manager:set_hat(GEAR.spinner_hat)
  State.gear_manager:set_tool_left(GEAR.split_keyboard)

  -- Create gear management overlay similar to shop
  local Container = require "ui.components.container"
  local Inventory = require "ui.components.inventory"
  local ScaledImg = require "ui.components.scaled-img"

  local overlay = Container.new {
    box = Box.new(
      Position.new(0, 0),
      Config.window_size.width,
      Config.window_size.height
    ),
    z = Z.GEAR_SELECTION_OVERLAY,
  }

  -- Add armory background
  local background_img = ScaledImg.new {
    box = Box.new(
      Position.new(0, 0),
      Config.window_size.width,
      Config.window_size.height
    ),
    texture = Asset.sprites.armory_background,
    scale_style = "stretch",
  }
  background_img.z = 1 -- Behind everything else
  overlay:append_child(background_img)

  -- Add escape key handling to close overlay
  overlay._update = function(self, dt)
    if love.keyboard.isDown "escape" then
      UI.root:remove_child(overlay)
      logger.info "Closed gear management overlay via escape key"
    end
  end

  UI.root:append_child(overlay)

  local inventory = Inventory.new {
    box = Box.fullscreen(),
    z = Z.GEAR_SELECTION_INVENTORY,
  }
  overlay:append_child(inventory)

  -- Add close button
  local close_button = ButtonElement.new {
    box = Box.new(Position.new(40, 40), 100, 40),
    label = "Close",
    on_click = function()
      UI.root:remove_child(overlay)
      logger.info "Closed gear management overlay"
    end,
  }
  overlay:append_child(close_button)

  self.overlay = overlay
end

function test_ui:update() end

function test_ui:draw()
  -- UI:debug_print_ui()
  -- error ""
end

function test_ui:keypressed() end

function test_ui:exit()
  if self.overlay then
    UI.root:remove_child(self.overlay)
  end
end

function test_ui:mousemoved() end

return require("vibes.base-mode").wrap(test_ui)
