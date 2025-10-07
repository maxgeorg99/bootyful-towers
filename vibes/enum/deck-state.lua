---@diagnostic disable-next-line: duplicate-doc-alias
---@enum DeckState
local deck_state = {
  INIT = "INIT",
  READY = "READY",
  PLAYING = "PLAYING",
  ACTION_STATE = "ACTION_STATE",
  DONE = "DONE",
}

---@diagnostic disable-next-line: duplicate-doc-alias
---@enum DeckState
return require("vibes.enum").new("DeckState", deck_state)
