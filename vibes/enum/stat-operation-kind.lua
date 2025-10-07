---@diagnostic disable-next-line: duplicate-doc-alias
---@enum StatOperationKind
local stat_operation_kind = {
  ADD_BASE = "ADD_BASE",
  ADD_MULT = "ADD_MULT",
  MUL_MULT = "MUL_MULT",
  -- SET_BASE = "SET_BASE",
}

---@diagnostic disable-next-line: duplicate-doc-alias
---@enum StatOperationKind
return require("vibes.enum").new("StatOperationKind", stat_operation_kind)
