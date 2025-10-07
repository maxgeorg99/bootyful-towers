local Level = require "vibes.level"

---@class (exact) vibes.Level.One : vibes.Level
---@field new fun(): vibes.Level.One
---@field init fun(self: vibes.Level.One)
local LevelOne = class("vibes.Level.One", { super = Level })

--- Creates a new LevelOne map
function LevelOne:init()
  Level.init(self, {
    id = "010",
    level_data_path = "assets/level-json/Level1.json",
  })
end

function LevelOne:on_start() print "Start hook" end
function LevelOne:on_draw() print "Draw hook" end
function LevelOne:on_play() print "Play hook" end
function LevelOne:on_spawn() end
function LevelOne:on_end() print "End hook" end
function LevelOne:on_complete() print "Complete hook" end
function LevelOne:on_game_over() print "Game over hook" end

return LevelOne
