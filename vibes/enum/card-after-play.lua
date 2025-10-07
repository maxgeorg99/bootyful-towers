---@diagnostic disable-next-line: duplicate-doc-alias
---@enum CardAfterPlay
local card_after_play = {
  DISCARD = "DISCARD",
  EXHAUST = "EXHAUST",
  NEVER = "NEVER",
}

---@diagnostic disable-next-line: duplicate-doc-alias
---@enum CardAfterPlay
return require("vibes.enum").new("CardAfterPlay", card_after_play)
