local Label = require "ui.components.label"
local ScaledImage = require "ui.components.scaled-img"

local SCALE = 1.75

---@class (exact) ui.components.player.GoldDisplay : layout.Layout
---@field new fun(opts: ui.components.player.GoldDisplay.Opts): ui.components.player.GoldDisplay
---@field init fun(self: ui.components.player.GoldDisplay, opts: ui.components.player.GoldDisplay.Opts)
---@field super layout.Layout
---@field _type "ui.components.player.GoldDisplay"
---@field label ui.components.Label
---@field previous_gold number
local GoldDisplay =
  class("ui.components.player.GoldDisplay", { super = Layout })

---@class ui.components.player.GoldDisplay.Opts
---@field box ui.components.Box

---@param opts? ui.components.player.GoldDisplay.Opts
function GoldDisplay:init(opts)
  opts = opts or {}

  Layout.init(self, {
    name = "GoldDisplay",
    box = opts.box or Box.empty(),
    flex = {
      direction = "row",
      justify_content = "start",
      align_items = "center",
      gap = 8,
    },
  })

  local label = Label.new(Asset.fonts.bignumbers_24, "0", { 1, 0.8, 0.2, 1 }) -- Gold color
  local img = ScaledImage.new {
    box = Box.new(Position.zero(), 28, 28),
    texture = Asset.sprites.coin_icon,
    scale_style = "fit",
  }

  self.label = label
  self.previous_gold = 0

  self:append_child(img)
  self:append_child(label)
end

function GoldDisplay:_update()
  if State.player.gold ~= self.previous_gold then
    self.label:set_text(tostring(State.player.gold))
    self.previous_gold = State.player.gold
  end
end

function GoldDisplay:_render() Layout._render(self) end

return GoldDisplay
