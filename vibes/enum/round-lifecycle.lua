---@diagnostic disable-next-line: duplicate-doc-alias
---@enum RoundLifecycle
local round_lifecycle = {
  PLAYER_PREP = "PLAYER_PREP",
  PLAYER_TURN = "PLAYER_TURN",
  ENEMIES_SPAWN_START = "ENEMIES_SPAWN_START",
  ENEMIES_SPAWNING = "ENEMIES_SPAWNING",
  ENEMIES_DEFEATED = "ENEMIES_DEFEATED",
  WAVE_COMPLETE = "WAVE_COMPLETE",
  TROPHY_SELECTION = "TROPHY_SELECTION",
  LEVEL_COMPLETE = "LEVEL_COMPLETE",

  -- If health is <= 0 we are dead, go to new state.
  GAME_OVER = "GAME_OVER",

  -- Paused States, handled externally
  PLAYER_PROCESSING_DRAW = "PLAYER_PROCESSING_DRAW",
  TOWER_LEVELING = "TOWER_LEVELING",
  GEAR_SELECTION = "GEAR_SELECTION",
  CARD_SELECTION = "CARD_SELECTION",
  PRESS_YOUR_LUCK = "PRESS_YOUR_LUCK",
  PLACING_TOWER = "PLACING_TOWER",
}

---@diagnostic disable-next-line: duplicate-doc-alias
---@enum RoundLifecycle
return require("vibes.enum").new("RoundLifecycle", round_lifecycle)
