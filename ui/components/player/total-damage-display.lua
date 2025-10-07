local ScaledImage = require "ui.components.scaled-img"
local Text = require "ui.components.text"
local text = require "utils.text"
---@class (exact) ui.components.player.TotalDamageDealtDisplay : layout.Layout
---@field new fun(opts: ui.components.player.TotalDamageDealtDisplay.Opts): ui.components.player.TotalDamageDealtDisplay
---@field init fun(self: ui.components.player.TotalDamageDealtDisplay, opts: ui.components.player.TotalDamageDealtDisplay.Opts)
---@field super layout.Layout
---@field _type "ui.components.player.TotalDamageDealtDisplay"
---@field txt ui.Text.Item
---@field label ui.components.Label
---@field previous_total_damage_dealt number
---@field previous_gold number

local TotalDamageDealtDisplay =
  class("ui.components.player.TotalDamageDealtDisplay", { super = Layout })

---@class ui.components.player.TotalDamageDealtDisplay.Opts : Element.Opts

local function total_damage_string()
  --return NumberToString.number_to_string(State.stat_holder.total_damage_dealt)
  return text.format_number(State.stat_holder.total_damage_dealt)
end

---@param opts? ui.components.player.TotalDamageDealtDisplay.Opts
function TotalDamageDealtDisplay:init(opts)
  opts = opts or {}

  local cell_size = Config.grid.cell_size
  local _3_4_cell_size = 3 * cell_size / 4
  local box = Box.new(Position.new(0, 0), _3_4_cell_size, _3_4_cell_size)
  Element.init(self, box, opts)
  self.txt = {
    text = total_damage_string(),
  }
  self.label = Text.new {
    self.txt,
    box = Box.new(Position.zero(), _3_4_cell_size * 7, _3_4_cell_size),
    font = Asset.fonts.typography.h2,
    text_align = "left",
  }

  local img = ScaledImage.new {
    box = Box.new(Position.zero(), _3_4_cell_size, _3_4_cell_size),
    texture = Asset.icons[IconType.DAMAGE],
    scale_style = "fit",
  }

  local w = Config.grid.grid_width
  local h = Config.grid.grid_height
  local container = Layout.row {
    box = Box.new(Position.new(1490, 908), cell_size * 2, cell_size),
    flex = {
      align_items = "start",
      justify_content = "start",
      gap = 8,
    },
    els = {
      img,
      self.label,
    },
  }

  self:append_child(container)
end

function TotalDamageDealtDisplay:_update(dt)
  self.txt.text = total_damage_string()
end

function TotalDamageDealtDisplay:_render() Layout._render(self) end

return TotalDamageDealtDisplay
