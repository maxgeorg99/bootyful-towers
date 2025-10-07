---@diagnostic disable-next-line: duplicate-doc-alias
---@enum ActionResult
local action_result = {
  ACTIVE = "ACTIVE",
  CANCEL = "CANCEL",
  COMPLETE = "COMPLETE",
}

---@diagnostic disable-next-line: duplicate-doc-alias
---@enum ActionResult
return require("vibes.enum").new("ActionResult", action_result)
