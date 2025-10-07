local ButtonElement = require "ui.elements.button"
local UIRootElement = require "ui.components.ui-root-element"

---@class vibes.BeatGameMode: vibes.BaseMode
local BeatGameMode = {}

function BeatGameMode:enter()
  self.timer = 0

  pcall(function()
    self.video_source = love.video.newVideoStream "assets/videos/victory.ogv"
    self.video = love.graphics.newVideo(self.video_source)
    self.video:play()
  end)

  -- Create UI elements
  local ui = UIRootElement.new()

  -- Add buttons like game-over mode
  local button_height = Config.ui.menu_buttons.height
  local button_width = Config.ui.menu_buttons.width
  local button_spacing = Config.ui.menu_buttons.spacing

  local total_width = button_width * 2 + button_spacing
  local start_x = (Config.window_size.width - total_width) / 2
  local menu_offset = start_x + button_width + button_spacing

  local replay_button = ButtonElement.new {
    box = Box.from(
      start_x,
      Config.window_size.height * 0.85,
      button_width,
      button_height
    ),
    label = "Play Again",
    on_click = function()
      RESET_STATE()
      State.mode = ModeName.MAP
    end,
  }

  local menu_button = ButtonElement.new {
    box = Box.from(
      menu_offset,
      Config.window_size.height * 0.85,
      button_width,
      button_height
    ),
    label = "Main Menu",
    on_click = function()
      RESET_STATE()
      State.mode = ModeName.MAIN_MENU
    end,
  }

  ui:append_child(replay_button)
  ui:append_child(menu_button)
  UI.root:append_child(ui)
end

function BeatGameMode:exit()
  if self.video then
    self.video:release()
  end

  if self.video_source then
    self.video_source:release()
  end
end

function BeatGameMode:update(dt)
  self.timer = self.timer + dt
  -- Remove auto-transition - let player choose when to continue
end

function BeatGameMode:draw()
  love.graphics.setColor(1, 1, 1, 1)

  if self.video and self.video:isPlaying() then
    -- Draw video if available and playing
    local video_width = self.video:getWidth()
    local video_height = self.video:getHeight()
    local scale_x = Config.window_size.width / video_width
    local scale_y = Config.window_size.height / video_height
    local scale = math.min(scale_x, scale_y)

    local x = (Config.window_size.width - video_width * scale) / 2
    local y = (Config.window_size.height - video_height * scale) / 2

    love.graphics.draw(self.video, x, y, 0, scale, scale)
  else
    -- Fall back to image if no video or video finished
    local image = Asset.sprites.game_victory
    local image_width = image:getWidth()
    local image_height = image:getHeight()
    local scale_x = Config.window_size.width / image_width
    local scale_y = Config.window_size.height / image_height
    local scale = math.min(scale_x, scale_y)

    local x = (Config.window_size.width - image_width * scale) / 2
    local y = (Config.window_size.height - image_height * scale) / 2

    love.graphics.draw(image, x, y, 0, scale, scale)
  end

  -- Draw victory text with shadow for better visibility
  love.graphics.setColor(0, 0, 0, 0.8)
  love.graphics.setFont(Asset.fonts.insignia_48)
  love.graphics.printf(
    "VICTORY!",
    2,
    Config.window_size.height * 0.1 + 2,
    Config.window_size.width,
    "center"
  )

  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.printf(
    "VICTORY!",
    0,
    Config.window_size.height * 0.1,
    Config.window_size.width,
    "center"
  )

  love.graphics.setColor(1, 1, 1, 1)
end

function BeatGameMode:keypressed(key)
  if key == "escape" or key == "space" then
    RESET_STATE() -- Reset the entire game state
    State.mode = ModeName.MAIN_MENU
    return true
  end
  return false
end

function BeatGameMode:mousepressed() return false end
function BeatGameMode:mousereleased() return false end
function BeatGameMode:mousemoved() return false end
function BeatGameMode:textinput() return false end

return BeatGameMode
