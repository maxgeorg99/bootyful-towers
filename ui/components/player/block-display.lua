local Label = require "ui.components.label"
local ScaledImage = require "ui.components.scaled-img"

local SCALE = 1.75

---@class (exact) ui.components.player.BlockDisplay : layout.Layout
---@field new fun(opts: ui.components.player.BlockDisplay.Opts): ui.components.player.BlockDisplay
---@field init fun(self: ui.components.player.BlockDisplay, opts: ui.components.player.BlockDisplay.Opts)
---@field super layout.Layout
---@field _type "ui.components.player.BlockDisplay"
---@field label ui.components.Label
---@field previous_block number
local BlockDisplay =
  class("ui.components.player.BlockDisplay", { super = Layout })

---@class ui.components.player.BlockDisplay.Opts
---@field box ui.components.Box

---@param opts? ui.components.player.BlockDisplay.Opts
function BlockDisplay:init(opts)
  opts = opts or {}

  Layout.init(self, {
    name = "BlockDisplay",
    box = opts.box or Box.empty(),
    flex = {
      direction = "row",
      justify_content = "start",
      align_items = "center",
      gap = 8,
    },
  })

  local label = Label.new(Asset.fonts.bignumbers_24, "0", { 0.7, 0.8, 1.0, 1 }) -- Light blue color for block
  local img = ScaledImage.new {
    box = Box.new(Position.zero(), 28, 28),
    texture = Asset.icons[IconType.SHIELD],
    scale_style = "fit",
  }

  self.label = label
  self.previous_block = 0

  self:append_child(img)
  self:append_child(label)
end

function BlockDisplay:_update()
  if State.player.block ~= self.previous_block then
    self.label:set_text(tostring(State.player.block))
    self.previous_block = State.player.block
  end
end

function BlockDisplay:_render() Layout._render(self) end

return BlockDisplay
