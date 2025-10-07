local Container = require "ui.components.container"
local StatUI = require "ui.components.stat"
local Tower = require "vibes.tower.base"

local BACKGROUND_COLOR_1 = { 0.1, 0.1, 0.1, 1 }
local BACKGROUND_COLOR_2 = { 0.2, 0.2, 0.2, 1 }
local background_colors = { BACKGROUND_COLOR_1, BACKGROUND_COLOR_2 }

local icon_size = 32
local icon_w_padding = 8
local icon_h_padding = 8
local stat_per_column = 4
local num_columns = 2

local stat_width, stat_height =
  StatUI.calculate_geometry(icon_size, icon_w_padding, icon_h_padding)

---@class (exact) components.TowerOverviewBottom.Opts : Element.Opts
---@field tower vibes.Tower
---@field position vibes.Position

---@class (exact) components.TowerOverviewBottom : Element
---@field new fun(opts: components.TowerOverviewBottom.Opts): components.TowerOverviewBottom
---@field init fun(self: components.TowerOverviewBottom, opts: components.TowerOverviewBottom.Opts)
---@field tower vibes.Tower
---@field _layout layout.Layout
local TowerOverviewBottom =
  class("components.TowerOverviewBottom", { super = Element })

---@param opts components.TowerOverviewBottom.Opts
function TowerOverviewBottom:init(opts)
  validate(opts, {
    tower = Tower,
    position = Position,
  })

  self.tower = opts.tower

  local box = Box.new(
    opts.position,
    stat_width * num_columns,
    stat_height * stat_per_column + 10
  )
  Element.init(self, box, opts)

  self.name = "TowerOverview"

  self:_setup_layout()
end

function TowerOverviewBottom:_setup_layout()
  local _, _, width, height = self:get_geo()

  local stats_to_display = self:_get_tower_stats()

  if #stats_to_display == 0 then
    return
  end

  local column_width = stat_width

  local columns = {}
  for col = 1, num_columns do
    local column_stats = {}
    local start_idx = (col - 1) * stat_per_column + 1
    local end_idx = math.min(col * stat_per_column, #stats_to_display)

    for i = start_idx, end_idx do
      local stat_data = stats_to_display[i]

      local stat_component = StatUI.new {
        field = stat_data.field,
        stat = stat_data.stat,
        icon_size = icon_size,
        icon_w_padding = icon_w_padding,
        icon_h_padding = icon_h_padding,
      }

      local x, y, w, h = stat_component:get_geo()
      local container = Container.new {
        box = Box.from(x, y, w, h),
        background = background_colors[i % 2 + 1],
        els = { stat_component },
      }

      table.insert(column_stats, container)
    end

    local column = Layout.col {
      box = Box.new(Position.zero(), column_width, height),
      flex = {
        align_items = "start",
        justify_content = "start",
        gap = 4,
      },
      els = column_stats,
    }

    table.insert(columns, column)
  end

  self._layout = Layout.row {
    box = Box.new(Position.zero(), width, height),
    flex = {
      align_items = "start",
      justify_content = "start",
    },
    els = columns,
  }

  self:append_child(self._layout)
end

---@param tower vibes.Tower
function TowerOverviewBottom:set_tower(tower)
  for _, child in ipairs(self.children) do
    self:remove_child(child)
  end

  self.tower = tower
  self:_setup_layout()
end

---@return {field: TowerStatField, stat: vibes.Stat}[]
function TowerOverviewBottom:_get_tower_stats()
  local stats = {}

  for _, field in ipairs(TowerStatFieldOrder) do
    local stat = self.tower.stats_manager.result[field]
    if stat and stat.base and stat.mult and stat.value and stat.value > 0 then
      table.insert(stats, {
        field = field,
        stat = stat,
      })
    end
  end

  return stats
end

function TowerOverviewBottom:_render() end

return TowerOverviewBottom
