local Text = require "ui.components.text"
local text = require "utils.text"
local STAT_ROW_H = 40

---@class (exact) components.TowerStatsTable.Opts
---@field box ui.components.Box
---@field tower vibes.Tower
---@field upgrade? tower.UpgradeOption

---@class (exact) components.TowerStatsTable : layout.Layout, mixin.ReactiveList
---@field new fun(opts: components.TowerStatsTable.Opts):components.TowerStatsTable
---@field init fun(self: components.TowerStatsTable, opts: components.TowerStatsTable.Opts)
---@field tower vibes.Tower
---@field upgrade? tower.UpgradeOption
---@field stats  { id: number, field: TowerStatField, stat: vibes.Stat }[]
---@field reset fun(self:components.TowerStatsTable)
local TowerStatsTable = class("components.TowerStatsTable", { super = Element })

function TowerStatsTable:init(opts)
  validate(opts, { box = "ui.components.Box", tower = "vibes.Tower" })

  self.tower = opts.tower
  self.upgrade = opts.upgrade
  self.stats = self:_order_stats()

  Element.init(self, opts.box)

  local gap = 10

  local height = #self.stats * (STAT_ROW_H + (gap * 1.2))

  self:set_height(height)

  local _, _, self_w, _ = self:get_geo()
  local layout = Layout.new {
    name = "TowerStatsTable(Layout)",
    box = Box.new(Position.zero(), self_w, height),
    els = (function()
      local rows = {}
      for idx, _ in ipairs(self.stats) do
        table.insert(rows, self:_get_stats_row(idx))
      end
      return rows
    end)(),
    flex = {
      direction = "column",
      justify_content = "start",
      align_items = "start",
      gap = gap,
    },
  }

  EventBus:listen_tower_upgrade_selected(
    function(evt) self.upgrade = evt.upgrade end
  )

  self:append_child(layout)
end

function TowerStatsTable:reset()
  self.upgrade = nil
  self.stats = self:_order_stats()
end

function TowerStatsTable:_render() end

---@param entry_idx number
---@return Element?
function TowerStatsTable:_get_stats_row(entry_idx)
  local _, _, w, _ = self:get_geo()

  local font = Asset.fonts.typography.tooltip_stat
  local row_h = STAT_ROW_H
  local row_w = w
  local col_w = (row_w / 5)
  local col_padding = 0

  local color = Colors.black:opacity(0.4)

  if entry_idx % 2 ~= 0 then
    color = Colors.black:opacity(0.3)
  end

  local row = Layout.row {
    name = "TowerDetatils(StatRow)",
    box = Box.new(Position.new(0, 0), row_w, row_h),
    background = color,
    rounded = 5,
    flex = {
      gap = 0,
    },
    els = {
      Layout.rectangle { w = 0, h = row_h },
      Text.new {
        function()
          local entry = self.stats[entry_idx]
          local field = entry.field
          local stat = entry.stat
          return {
            {
              icon = Asset.icons[TowerStatFieldIcon[field]],
              color = Colors.white,
            },
            {
              text = text.format_number(stat.base),
            },
          }
        end,
        text_align = "right",
        font = font,
        box = Box.new(Position.zero(), col_w, row_h),
      },

      Layout.rectangle { w = 4, h = row_h },

      -- Base Value Modifier
      Text.new {
        function()
          local entry = self.stats[entry_idx]
          local field = entry.field
          return {
            {
              text = self:_get_upgrade_label(field, "BASE"),
              color = Colors.white,
              text_align = "left",
            },
          }
        end,
        box = Box.new(Position.zero(), col_w * 0.50, row_h),
        font = font,
        color = Colors.white,
        text_align = "left",
        padding = col_padding,
      },

      Text.new {
        function()
          local entry = self.stats[entry_idx]
          local stat = entry.stat
          return {
            {
              text = "x " .. text.format_number(stat.mult),
              color = Colors.white,
            },
          }
        end,
        box = Box.new(Position.zero(), col_w, row_h),
        font = font,
        padding = col_padding,
      },

      -- Mult Value Modifier
      Text.new {
        function()
          local entry = self.stats[entry_idx]
          return {
            {
              text = self:_get_upgrade_label(entry.field, "MULT"),
              color = Colors.white,
            },
          }
        end,
        box = Box.new(Position.zero(), col_w * 0.80, row_h),
        font = font,
        padding = col_padding,
        text_align = "left",
      },

      Text.new {
        function()
          local entry = self.stats[entry_idx]
          local stat = entry.stat:clone()
          local stat_op = self:_get_stat_field_upgrade(entry.field)

          local value = string.format("= %s", text.format_number(stat.value))

          if stat_op then
            local direction = self:_get_upgrade_direction(stat_op)
            local upgrade = stat_op.operation:apply(stat)
            value = string.format("{%s:%s}", direction, "= " .. upgrade.value)
          end

          return {
            {
              text = value,
              color = Colors.white,
            },
          }
        end,
        box = Box.new(Position.zero(), col_w, row_h),
        font = font,
        padding = col_padding,
        text_align = "left",
      },
    },
  }

  return row
end

---@return {id:number, field:TowerStatField, stat:vibes.Stat}[]
function TowerStatsTable:_order_stats()
  local stats = {}

  for idx, key in ipairs(TowerStatFieldOrder) do
    local stat = self.tower.stats_manager.result[key]
    ---@cast stat vibes.Stat
    if Stat.is(stat) then
      --Temp limiter to remove unwanted stats from table
      if
        stat.value ~= 0
        and stat.value ~= 1
        and key ~= TowerStatField.ENEMY_TARGETS
      then
        table.insert(
          stats,
          { id = idx, field = key, stat = self.tower.stats_manager.result[key] }
        )
      end
    end
  end

  return stats
end

---@param stat_op tower.StatOperation
function TowerStatsTable:_get_upgrade_direction(stat_op)
  local op_kind = stat_op.operation.kind

  local op_variation_kind = "value"

  if
    op_kind == StatOperationKind.ADD_BASE
    or op_kind == StatOperationKind.ADD_MULT
    or op_kind == StatOperationKind.MUL_MULT
  then
    op_variation_kind = "increase"
  end

  return op_variation_kind
end

---@param field TowerStatField
function TowerStatsTable:_get_upgrade_label(field, kind)
  local stat_op = self:_get_stat_field_upgrade(field)

  if not stat_op then
    return ""
  end

  local op_kind = stat_op.operation.kind
  local op_label = stat_op.operation.label
  local op_value = stat_op.operation.value

  assert(
    Enum.length(StatOperationKind) == 3,
    "enum.StatOperationKind count has changed. Update components.TowerStatsTabe!"
  )

  local check = {
    [StatOperationKind.ADD_BASE] = "BASE",
    [StatOperationKind.MUL_MULT] = "MULT",
    [StatOperationKind.ADD_MULT] = "MULT",
  }

  if check[op_kind] ~= kind then
    return ""
  end

  local op_variation_kind = "value"

  if
    op_kind == StatOperationKind.ADD_BASE
    or op_kind == StatOperationKind.ADD_MULT
    or op_kind == StatOperationKind.MUL_MULT
  then
    op_variation_kind = "increase"
  else
    op_variation_kind = "decrease"
  end

  return string.format(
    "{%s:%s}{%s:%d}",
    op_variation_kind,
    op_label,
    op_variation_kind,
    op_value
  )
end

function TowerStatsTable:_get_stat_field_upgrade(field)
  if not (self.upgrade and self.upgrade.operations) then
    return nil
  end
  for _, op in ipairs(self.upgrade.operations) do
    if op.field == field then
      return op
    end
  end
  return nil
end

function TowerStatsTable:get_reactive_list() return self:_order_stats() end

function TowerStatsTable:create_element_for_item(stat)
  return self:_get_stats_row(stat)
end

return TowerStatsTable
