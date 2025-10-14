local GameModes = require "vibes.enum.mode-name"

---@class vibes.SplashScreen : vibes.BaseMode
---@field logo vibes.Texture
---@field elapsed_time number
---@field fade_in_duration number
---@field display_duration number
---@field fade_out_duration number
---@field opacity number
local SplashScreen = {}

function SplashScreen:enter()
  self.logo = Asset.sprites.logo
  self.elapsed_time = 0
  self.fade_in_duration = 0.5
  self.display_duration = 2.5
  self.fade_out_duration = 0.5
  self.opacity = 0
end

function SplashScreen:exit()
  -- Clean up if needed
end

function SplashScreen:update(dt)
  self.elapsed_time = self.elapsed_time + dt

  local total_duration = self.fade_in_duration + self.display_duration + self.fade_out_duration

  if self.elapsed_time < self.fade_in_duration then
    -- Fade in
    self.opacity = self.elapsed_time / self.fade_in_duration
  elseif self.elapsed_time < self.fade_in_duration + self.display_duration then
    -- Full display
    self.opacity = 1
  elseif self.elapsed_time < total_duration then
    -- Fade out
    local fade_progress = (self.elapsed_time - self.fade_in_duration - self.display_duration) / self.fade_out_duration
    self.opacity = 1 - fade_progress
  else
    -- Transition to main menu
    State.mode = GameModes.MAIN_MENU
  end
end

function SplashScreen:draw()
  -- Draw black background
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.rectangle("fill", 0, 0, Config.window_size.width, Config.window_size.height)

  -- Draw logo centered with fade effect
  love.graphics.setColor(1, 1, 1, self.opacity)

  local logo_width = self.logo:getWidth()
  local logo_height = self.logo:getHeight()

  local x = (Config.window_size.width - logo_width) / 2
  local y = (Config.window_size.height - logo_height) / 2

  love.graphics.draw(self.logo, x, y)

  -- Reset color
  love.graphics.setColor(1, 1, 1, 1)
end

---@param key string
function SplashScreen:keypressed(key)
  -- Skip splash screen on any key press
  State.mode = GameModes.MAIN_MENU
  return true
end

return require("vibes.base-mode").wrap(SplashScreen)
