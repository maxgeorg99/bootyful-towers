local MIDDLE_WIDTH = Asset.sprites.parchment_middle:getWidth()
local MIDDLE_HEIGHT = Asset.sprites.parchment_middle:getHeight()
local LEFT_WIDTH = Asset.sprites.parchment_edge_left:getWidth()
local LEFT_HEIGHT = Asset.sprites.parchment_edge_left:getHeight()
local RIGHT_WIDTH = Asset.sprites.parchment_edge_right:getWidth()
local RIGHT_HEIGHT = Asset.sprites.parchment_edge_right:getHeight()

---@class (exact) ui.components.FancyTooltipsOpts
---@field text string
---@field position vibes.Position
---@field fade_duration_ms number

---@class (exact) ui.components.FancyTooltip : Element
---@field text string
---@field position vibes.Position
---@field display_width number
---@field lines string[]
---@field font love.Font
---@field fade_duration_ms number
---@field parchment_edge_left vibes.Texture
---@field parchment_edge_right vibes.Texture
---@field parchment_left vibes.Texture
---@field parchment_right vibes.Texture
---@field parchment_middle vibes.Texture
---
---@field _fit_text fun(self: ui.components.FancyTooltip)
---@field _scale_background fun(self: ui.components.FancyTooltip)
---@field new fun(opts: ui.components.FancyTooltipsOpts): ui.components.FancyTooltip
---@field init fun(self: ui.components.FancyTooltip, opts: ui.components.FancyTooltipsOpts)
local FancyTooltip = class("ui.components.FancyTooltip", { super = Element })

function FancyTooltip:init(opts)
  validate(opts, {
    text = "string",
    position = "vibes.Position",
    fade_duration_ms = "number",
  })
  self.text = opts.text
  self.font = Asset.fonts.insignia_24
  self.position = opts.position
  self.fade_duration_ms = opts.fade_duration_ms
  self.parchment_edge_left = Asset.sprites.parchment_edge_left
  self.parchment_edge_right = Asset.sprites.parchment_edge_right
  self.parchment_left = Asset.sprites.parchment_left
  self.parchment_right = Asset.sprites.parchment_right
  self.parchment_middle = Asset.sprites.parchment_middle
end

function FancyTooltip:_fit_text()
  self.lines = {}
  local words = {}

  for word in self.text:gmatch "%S+" do
    table.insert(words, word)
  end

  local current_line = ""
  for _, word in ipairs(words) do
    if self.font:getWidth(current_line .. " " .. word) > self.display_width then
      table.insert(self.lines, current_line)
      current_line = word
    else
      current_line = current_line .. " " .. word
    end
  end
  if current_line ~= "" then
    table.insert(self.lines, current_line)
  end
end

function FancyTooltip:_scale_background() end

function FancyTooltip:_render()
  local x, y, width, height = self:get_geo()
  love.graphics.push()
  love.graphics.setFont(self.font)
  love.graphics.setColor(0, 0, 0, 0.8)

  love.graphics.rectangle("fill", x, y, width, height + 15, 10, 10, 80)
  love.graphics.pop()
end
