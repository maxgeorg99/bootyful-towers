---@diagnostic disable-next-line: duplicate-doc-alias
---@enum TextControl
local text_control = {
  NewLine = "_NEW_LINE_",
}

---@diagnostic disable-next-line: duplicate-doc-alias
---@enum TextControl
return require("vibes.enum").new(
  "TextControl",
  text_control,
  { skip_value_check = true }
)
