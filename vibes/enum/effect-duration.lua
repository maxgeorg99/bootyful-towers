---@diagnostic disable-next-line: duplicate-doc-alias
---@enum EffectDuration
local effect_duration = {
  END_OF_WAVE = "END_OF_WAVE",
  END_OF_MAP = "END_OF_MAP",
  END_OF_GAME = "END_OF_GAME",
}

---@diagnostic disable-next-line: duplicate-doc-alias
---@enum EffectDuration
return require("vibes.enum").new("EffectDuration", effect_duration)
