require "ui.components.ui"
---@class vibes.TestTileset : vibes.BaseMode
local test_tileset = {}

function test_tileset:enter()
  local r = 0
  local c = 0

  love.graphics.setColor(1, 1, 1)
  for _, row in ipairs(Asset.tilesets.grass) do
    for _, sprite in ipairs(row) do
      print("drawing sprite", r, c)
      love.graphics.draw(sprite, c * 24, r * 24)
      c = c + 1
    end
    r = r + 1
    c = 0
  end

  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(Asset.tilesets.grass_full, 0, 0, 0, 1, 1, 0, 0)
end

function test_tileset:update(dt) UI:update(dt) end

function test_tileset:draw()
  local r = 0
  local c = 0

  love.graphics.setColor(1, 1, 1)
  for _, row in ipairs(Asset.tilesets.grass) do
    for _, sprite in ipairs(row) do
      love.graphics.draw(sprite, c * 24 * 2, r * 24 * 2, 0, 2, 2)
      c = c + 1
    end
    r = r + 1
    c = 0
  end

  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(Asset.tilesets.grass_full, r * 48, c * 48, 0, 2, 2, 0, 0)
end
function test_tileset:keypressed() end

function test_tileset:exit()
  -- UI:debug_print_ui()
  -- UI.root:remove_child(self.ui)
end

function test_tileset:mousemoved() end

return require("vibes.base-mode").wrap(test_tileset)
