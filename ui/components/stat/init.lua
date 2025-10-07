local Container = require "ui.components.container"
local Img = require "ui.components.img"
local Text = require "ui.components.text"

local TEXT_COLOR = Colors.white:get()

---@class (exact) components.Stat.Opts : Element.Opts
---@field field TowerStatField
---@field stat vibes.Stat
---@field upgrade? tower.UpgradeOption
---@field icon_size number
---@field icon_w_padding number
---@field icon_h_padding number
---@field on_select? fun(self: components.Stat)

---@class (exact)components.Stat : Element
---@field calculate_geometry fun(icon_size: number, icon_w_padding: number, icon_h_padding: number): number, number
---@field box ui.components.Box
---@field stat vibes.Stat
---@field field  TowerStatField
---@field icon vibes.Texture
---@field icon_size number
---@field icon_w_padding number
---@field icon_h_padding number
---@field font love.Font
---@field upgrade? tower.UpgradeOption
---@field new fun(opts: components.Stat.Opts): components.Stat
---@field init fun(self: components.Stat, options:components.Stat.Opts)
---@field _on_select? fun(self: components.Stat)
---@field calculate_geometry fun(icon_size: number, icon_w_padding: number, icon_h_padding: number): number, number
local Stat = class("components.Stat", { super = Element })

local PADDING = 6
local STAT_WIDTH = 60
local SYMBOL_WIDTH = 12

local function row_width(icon_size, icon_w_padding)
  return (icon_size + icon_w_padding)
    + STAT_WIDTH * 3
    + SYMBOL_WIDTH * 2
    + PADDING * 6
end

local function row_height(icon_size, icon_h_padding)
  return icon_size + icon_h_padding
end

---@param icon_size number
---@param icon_w_padding number
---@param icon_h_padding number
---@return number width
---@return number height
function Stat.calculate_geometry(icon_size, icon_w_padding, icon_h_padding)
  return row_width(icon_size, icon_w_padding),
    row_height(icon_size, icon_h_padding)
end

---@param text string
---@param height number
---@return component.Text
local function symbol(text, height)
  return Text.new {
    {
      text = text,
    },
    box = Box.new(Position.new(0, 0), SYMBOL_WIDTH, height),
    text_align = "left",
    vertical_align = "center",
  }
end

function Stat:init(opts)
  validate(opts, {
    stat = require "vibes.data.stat",
    field = Either { TowerStatField, nil },
    icon_size = "number",
    icon_w_padding = "number",
    icon_h_padding = "number",
  })

  self.field = opts.field
  self.stat = opts.stat
  self.icon = Asset.icons[TowerStatFieldIcon[self.field]]
  self.font = Asset.fonts.typography.tooltip_stat
  self.upgrade = opts.upgrade
  self.icon_size = opts.icon_size
  self.icon_w_padding = opts.icon_w_padding
  self.icon_h_padding = opts.icon_h_padding
  self._on_select = opts.on_select

  if self.upgrade then
    assert(
      #self.upgrade.operations == 1,
      "Upgrade must have exactly one operation"
    )
  end

  local width, height = self:get_stat_dims()
  local box = Box.new(Position.zero(), width, height)
  Element.init(self, box, opts)

  self.name = "Stat"

  self:_setup_layout()
end

---@return number width
---@return number height
function Stat:get_stat_dims()
  return row_width(self.icon_size, self.icon_w_padding),
    row_height(self.icon_size, self.icon_h_padding)
end

function Stat:_setup_layout()
  local row_width = row_width(self.icon_size, self.icon_w_padding)
  local row_height = row_height(self.icon_size, self.icon_h_padding)

  local _, icon_h = self.icon:getDimensions()
  local scale = self.icon_size / icon_h
  local icon = Img.new(self.icon, scale, scale, {})

  local icon_layout_vert = Layout.col {
    box = Box.new(Position.new(0, 0), row_height, row_height),
    flex = {
      align_items = "start",
      justify_content = "start",
      gap = 0,
    },
    els = {
      Layout.rectangle {
        h = self.icon_h_padding / 2 - 2,
        w = 1,
      },
      icon,
    },
  }

  local icon_layout_horiz = Layout.row {
    box = Box.new(Position.new(0, 0), row_height, row_height),
    flex = {
      align_items = "start",
      justify_content = "start",
      gap = 0,
    },
    els = {
      Layout.rectangle {
        h = 1,
        w = self.icon_w_padding,
      },
      icon_layout_vert,
    },
  }

  local img = Container.new {
    box = Box.new(Position.new(0, 0), row_height, row_height),
  }

  img:append_child(icon_layout_horiz)

  local layout = Layout.row {
    box = Box.new(Position.new(0, 0), row_width, row_height),
    flex = {
      align_items = "start",
      justify_content = "start",
      gap = PADDING,
    },
    els = {
      img,
      self:_get_base_upgrade_value(),
      symbol("x", row_height),
      self:_get_mult_upgrade_value(),
      symbol("=", row_height),
      self:_get_total_value_modified(),
    },
  }

  self:append_child(layout)
end

function Stat:_get_total_value_modified()
  -- Apply the upgrade operation to get the new stat, or use current stat if no upgrade
  local new_stat = self.stat
  if self.upgrade then
    new_stat = self.upgrade.operations[1].operation:apply(self.stat)
  end

  return Text.new {
    function()
      local b = new_stat.value
      local str = self.field == TowerStatField.CRITICAL
          and tostring(math.floor(b * 100)) .. "%"
        or tostring(b)
      return {
        text = str,
        color = TEXT_COLOR,
      }
    end,
    font = self.font,
    box = Box.new(
      Position.new(0, 0),
      STAT_WIDTH,
      row_height(self.icon_size, self.icon_h_padding)
    ),
    text_align = "left",
    vertical_align = "center",
  }
end

---@return component.Text?
function Stat:_get_mult_upgrade_value()
  local texts = {
    function()
      return {
        text = tostring(self.stat.mult) .. " ",
        color = TEXT_COLOR,
      }
    end,
    box = Box.new(
      Position.new(0, 0),
      STAT_WIDTH,
      row_height(self.icon_size, self.icon_h_padding)
    ),
    font = self.font,
    text_align = "left",
    vertical_align = "center",
  }

  if self.upgrade then
    local value = self.upgrade.operations[1].operation.value
    local kind = self.upgrade.operations[1].operation.kind
    local symbol_text = kind == StatOperationKind.ADD_MULT and "+" or "×"
    local text_item = function()
      return {
        text = symbol_text .. " " .. tostring(value),
        color = TEXT_COLOR,
      }
    end
    table.insert(texts, text_item)
  end

  return Text.new(texts)
end

---@return component.Text?
function Stat:_get_base_upgrade_value()
  local texts = {
    function()
      local b = self.stat.base
      local str = self.field == TowerStatField.CRITICAL
          and tostring(math.floor(b * 100)) .. "%"
        or tostring(b)
      return {
        text = str,
        color = TEXT_COLOR,
      }
    end,
    box = Box.new(
      Position.new(0, 0),
      STAT_WIDTH,
      row_height(self.icon_size, self.icon_h_padding)
    ),
    font = self.font,
    text_align = "left",
    vertical_align = "center",
  }

  if self.upgrade then
    local value = self.upgrade.operations[1].operation.value
    local kind = self.upgrade.operations[1].operation.kind
    if kind == StatOperationKind.ADD_BASE then
      local text_item = function()
        return {
          text = "+ " .. tostring(value),
          color = TEXT_COLOR,
        }
      end
      table.insert(texts, text_item)
    end
  end

  return Text.new(texts)
end

function Stat:_render() end

function Stat:_update() end

function Stat:_click()
  if self._on_select then
    self._on_select(self)
  end
end

return Stat
