---@diagnostic disable-next-line: duplicate-doc-alias
---@enum ForgeCraftState
local action_result = {
  READY = "READY",
  INVALID = "INVALID",
  MISSING = "MISSING",
}

---@diagnostic disable-next-line: duplicate-doc-alias
---@enum ForgeCraftState
return require("vibes.enum").new("ForgeCraftState", action_result)
