---@diagnostic disable-next-line: duplicate-doc-alias
---@enum ActionState
local action_state = {
  INITIALIZING = "INITIALIZING",
  WAITING = "WAITING",
  COMPLETED = "COMPLETED",
}

---@diagnostic disable-next-line: duplicate-doc-alias
---@enum ActionState
return require("vibes.enum").new("ActionState", action_state)
