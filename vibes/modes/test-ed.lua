local ArcherCard = require "vibes.card.card-tower-archer"
local EarthCard = require "vibes.card.card-tower-earth"
local EmberWatchCard = require "vibes.card.card-tower-emberwatch"
local GameMode = require "vibes.modes.game"

---@class vibes.TestED : vibes.GameMode
local test_ed = {}

local has_spawned_pool = false

function test_ed:generate_cards()
  local fire = EmberWatchCard.new {
    rarity = Rarity.RARE,
    level = 1,
  }

  fire:level_up_to(6)
  State.deck.draw_pile = {
    fire,
  }
end

function test_ed:enter()
  self:generate_cards()
  GameMode:enter()
end

function test_ed:update(dt) GameMode:update(dt) end

function test_ed:keyreleased(key) GameMode:keyreleased(key) end

function test_ed:keypressed(key)
  if key == "R" then
    self:generate_cards()
  end

  GameMode:keypressed(key)
end

function test_ed:draw() GameMode:draw() end

function test_ed:mousemoved() GameMode:mousemoved() end

function test_ed:exit() GameMode:exit() end

return require("vibes.base-mode").wrap(test_ed)
