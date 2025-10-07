---@diagnostic disable-next-line: duplicate-doc-alias
---@enum UpgradeHint
local upgrade_hint = {
  GOOD = "GOOD",
  BAD = "BAD",

  -- TODO: CANCELLED
  -- TODO: SUPER_GOOD
  -- TODO: PAIRS_WITH
  -- etc.
}

---@diagnostic disable-next-line: duplicate-doc-alias
---@enum UpgradeHint
return require("vibes.enum").new("UpgradeHint", upgrade_hint)
