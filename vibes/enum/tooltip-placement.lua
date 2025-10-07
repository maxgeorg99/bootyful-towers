---@diagnostic disable-next-line: duplicate-doc-alias
---@enum TooltipPlacement
local tooltip_placement = {
  TOP = "TOP",
  BOTTOM = "BOTTOM",
  RIGHT = "RIGHT",
  LEFT = "LEFT",
}

---@diagnostic disable-next-line: duplicate-doc-alias
---@enum TooltipPlacement
return require("vibes.enum").new("TooltipPlacement", tooltip_placement)
