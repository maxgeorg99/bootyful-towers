---@diagnostic disable-next-line: duplicate-doc-alias
---@enum DropzoneStatus
local dropzone_status = {
  HOVERING = "HOVERING",
  ACCEPTING = "ACCEPTING",
  REJECTED = "REJECTED",
  INACTIVE = "INACTIVE",
}

---@diagnostic disable-next-line: duplicate-doc-alias
---@enum DropzoneStatus
return require("vibes.enum").new("DropzoneStatus", dropzone_status)
