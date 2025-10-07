local Text = require "ui.components.text"
local TowerCard = require "vibes.card.base-tower-card"
local text = require "utils.text"

-- Constants for better maintainability
local TOOLTIP_PADDING = 20
local STAT_PADDING = 11
local STAT_ROW_HEIGHT = 55
local LEVEL_DIMENSION = 68
local POINTER_SIZE = 50
local ANIMATION_DURATION = 0.2

---@class (exact) components.TowerTooltip.Opts
---@field box? ui.components.Box
---@field tower_box ui.components.Box
---@field card vibes.TowerCard
---@field hide_description? boolean
---@field z? number

---@class (exact) components.TowerTooltip : Element
---@field new fun(opts: components.TowerTooltip.Opts): components.TowerTooltip
---@field init fun(self: components.TowerTooltip, opts: components.TowerTooltip.Opts)
---@field stats { id: number, field: TowerStatField }[]
---@field card vibes.TowerCard
---@field pointer_placement TooltipPlacement
---@field hide_description boolean
---@field _layout? layout.Layout
---@field _tower_box ui.components.Box
---@field _width number
---@field _cached_font? love.Font
local TowerTooltip = class("components.TowerTooltip", { super = Element })

function TowerTooltip:init(opts)
  validate(opts, {
    box = "Box?",
    tower_box = Box,
    card = TowerCard,
    hide_description = "boolean?",
    z = "number?",
  })

  local box = opts.box or Box.new(Position.zero(), 475, 100)

  Element.init(self, box, {
    z = F.if_nil(opts.z, Z.TOWER_OVERVIEW),
  })

  self.name = "TowerTooltip"
  self.card = opts.card
  self.hide_description = opts.hide_description or false
  self.stats = self:_order_stats()
  self.pointer_placement = TooltipPlacement.RIGHT
  self._tower_box = opts.tower_box
  self._width = 0
  self._cached_font = nil

  -- self:set_hidden(true)
  -- self:set_opacity(0)
  self:set_interactable(false)

  self:_calculate_positioning()
end

--- Calculate tooltip positioning relative to tower
function TowerTooltip:_calculate_positioning()
  local x, _, w, _ = self:get_geo()
  local tx, _, tw, th = self._tower_box:geo()

  if not self.hide_description then
    self:_setup_layout()
    self:set_y(((-self._layout:get_height() / 2) - 60) + (th / 2))
  end

  -- Determine tooltip placement to avoid going off-screen
  local _, _, tooltip_w, _ = self:get_geo()
  if tx - tooltip_w < 0 then
    self:set_x(x + tw + TOOLTIP_PADDING)
    self.pointer_placement = TooltipPlacement.LEFT
  else
    self.pointer_placement = TooltipPlacement.RIGHT
    self:set_x(x - w - TOOLTIP_PADDING)
  end
end

function TowerTooltip:_setup_layout()
  local _, _, w, _ = self:get_geo()

  self._layout = Layout.new {
    name = "TowerTooltip(Layout)",
    box = Box.new(Position.zero(), w, 60),
    els = {
      Layout.rectangle { w = w, h = 8 },
      Text.new {
        function()
          return {
            {
              text = self.card.tower.name or self.card.name,
              color = Colors.white:opacity(self:get_opacity()),
            },
          }
        end,
        box = Box.new(Position.zero(), w, 40),
        font = Asset.fonts.typography.h3,
        text_align = "left",
        padding = TOOLTIP_PADDING,
      },
    },
    flex = {
      justify_content = "center",
      gap = 0,
      align_items = "center",
      direction = "column",
    },
  }

  self:append_child(self._layout)
end

function TowerTooltip:_setup_stats_rows()
  local x, y, w, _ = self:get_geo()

  self._width = 0
  local row_offset = 0

  x = x + TOOLTIP_PADDING
  y = y + TOOLTIP_PADDING

  if not self.hide_description then
    y = y + 45
  end

  for idx, _ in ipairs(self.stats) do
    self:_render_stat_entry(idx, x, y)

    if row_offset == 0 and idx == #self.stats then
      if self.pointer_placement == TooltipPlacement.BOTTOM then
        self:set_x(-((self._width / 2) - (self._tower_box.width / 2) + 15))
      elseif self.pointer_placement == TooltipPlacement.RIGHT then
        self:set_x(-(self._width + 30) - TOOLTIP_PADDING)
      elseif self.pointer_placement == TooltipPlacement.LEFT then
        self:set_x(self._tower_box.width + TOOLTIP_PADDING)
      end
      self:set_width(self._width + 30)
    end

    if
      self._width + 50 > (w - (TOOLTIP_PADDING * 2)) and idx ~= #self.stats
    then
      row_offset = row_offset + STAT_ROW_HEIGHT
      y = y + row_offset
      self._width = 0
    end
  end

  if not self.hide_description then
    y = y + 40
    row_offset = row_offset + 50
  end

  self:set_height(80 + row_offset)
end

function TowerTooltip:_render_stat_entry(idx, x, y)
  local bg_color = Colors.white:opacity(0.4 * self:get_opacity())
  if idx % 2 == 0 then
    bg_color = Colors.white:opacity(0.3 * self:get_opacity())
  end

  local entry = self.stats[idx]
  local icon = Asset.icons[TowerStatFieldIcon[entry.field]]

  local icon_w = icon:getWidth()
  local icon_h = icon:getHeight()
  local value = text.format_number(self.card.tower:get_field_value(entry.field))

  -- Cache font to avoid repeated lookups
  if not self._cached_font then
    self._cached_font = Asset.fonts.typography.tooltip_stat
    self._cached_font:setFilter("nearest", "nearest")
  end

  local font_w = self._cached_font:getWidth(value)
  local padding = STAT_PADDING

  local tag_w = (padding * 4) + icon_w + font_w
  local tag_h = (padding * 2) + (padding / 2) + icon_h

  love.graphics.setFont(self._cached_font)

  self:with_color(
    bg_color,
    function()
      love.graphics.rectangle(
        "fill",
        x + self._width,
        y,
        tag_w,
        tag_h,
        5,
        5,
        80
      )
    end
  )

  self:with_color(Colors.white, function()
    love.graphics.draw(
      icon,
      x + self._width + padding,
      y + (padding / 2) + 1,
      0,
      2,
      2
    )

    love.graphics.printf(
      value,
      x + self._width + icon_w + (padding * 3),
      y + (padding / 2) + 2,
      font_w,
      "left"
    )
  end)

  self._width = self._width + tag_w + padding
end

---@return {id:number, field:TowerStatField}[]
function TowerTooltip:_order_stats()
  local tower_stats = self.card.tower.stats_base

  local stats = {}

  for idx, key in ipairs(TowerStatFieldOrder) do
    local stat = tower_stats[key]
    --- @cast stat vibes.Stat
    if Stat.is(stat) then
      if key ~= "enemy_targets" and stat.value ~= 0 and stat.value ~= 1 then
        table.insert(stats, { id = idx, field = key })
      end
    end
  end

  return stats
end

function TowerTooltip:enter_from_tower() end

function TowerTooltip:exit_tower() end

function TowerTooltip:_render()
  if #ActionQueue.items > 0 then
    return
  end

  local x, y, w, h = self:get_geo()

  love.graphics.setColor(Colors.gray:opacity(self:get_opacity()))

  -- Render background with pointer
  self:_render_background_with_pointer(x, y, w, h)

  -- Render level indicator if description is shown
  if not self.hide_description then
    self:_render_level_indicator(x, y, w, h)
  end

  -- Render stats
  self:_setup_stats_rows()
end

--- Render the tooltip background with pointer
function TowerTooltip:_render_background_with_pointer(x, y, w, h)
  local union = function()
    love.graphics.push()
    if self.pointer_placement == TooltipPlacement.RIGHT then
      love.graphics.translate(x + w - 15, y + h / 2)
      love.graphics.rotate(0.80)
    elseif self.pointer_placement == TooltipPlacement.LEFT then
      love.graphics.translate(x + 15, y + h / 2)
      love.graphics.rotate(0.80)
    elseif self.pointer_placement == TooltipPlacement.BOTTOM then
      love.graphics.translate(x + w / 2, y + h - 5)
      love.graphics.rotate(-0.80)
    end

    love.graphics.rectangle(
      "fill",
      -25,
      -35,
      POINTER_SIZE,
      POINTER_SIZE,
      10,
      10,
      120
    )
    love.graphics.pop()
    love.graphics.rectangle("fill", x, y, w, h, 20, 20, 80)
  end

  love.graphics.stencil(union, "replace", 1)
  love.graphics.setStencilTest("greater", 0)
  love.graphics.rectangle(
    "fill",
    0,
    0,
    love.graphics.getWidth(),
    love.graphics.getHeight()
  )
  love.graphics.setStencilTest()
end

--- Render the level indicator
function TowerTooltip:_render_level_indicator(x, y, w, h)
  love.graphics.push()

  local lvl_dim = LEVEL_DIMENSION
  love.graphics.translate(x + w - 25, y + 10)
  love.graphics.rotate(-0.40)

  love.graphics.setColor(Colors.black:opacity(0.3 * self:get_opacity()))
  love.graphics.rectangle("fill", -lvl_dim / 2, -lvl_dim / 2, lvl_dim, lvl_dim)

  love.graphics.setColor(Colors.red:opacity(self:get_opacity()))
  love.graphics.rectangle(
    "fill",
    -(lvl_dim - 5) / 2,
    -(lvl_dim + 10) / 2,
    lvl_dim,
    lvl_dim
  )

  love.graphics.pop()

  -- Level text
  love.graphics.setColor(Colors.white:opacity(self:get_opacity()))
  local lvl_x_offset = x + w - (lvl_dim - 20)

  love.graphics.setFont(Asset.fonts.typography.sub)
  love.graphics.print("LV", lvl_x_offset, y)

  lvl_x_offset = lvl_x_offset + 28
  love.graphics.setFont(Asset.fonts.typography.h4)
  love.graphics.print(self.card.tower.level, lvl_x_offset, y - 8)
end

function TowerTooltip:_update(_dt)
  if self:get_opacity() == 0 then
    self:set_hidden(true)
  else
    self:set_hidden(false)
  end

  if #ActionQueue.items > 0 then
    self.targets.opacity = 0
    self:set_scale(0.2)
    return
  end

  if self._tower_box:contains(State.mouse.x, State.mouse.y) then
    self.targets.opacity = 1
    self:set_scale(1)
  else
    self.targets.opacity = 0
    self:set_scale(0.2)
  end
end

return TowerTooltip
