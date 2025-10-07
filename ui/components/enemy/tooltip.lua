local ScaledImage = require "ui.components.scaled-img"
local Text = require "ui.components.text"
local text = require "utils.text"

---@class (exact) components.EnemyTooltip.Opts
---@field box? ui.components.Box
---@field enemy_box ui.components.Box
---@field enemy vibes.Enemy
---@field z? number

---@class (exact) components.EnemyTooltip : Element
---@field new fun(opts: components.EnemyTooltip.Opts): components.EnemyTooltip
---@field init fun(self: components.EnemyTooltip, opts: components.EnemyTooltip.Opts)
---@field enemy vibes.Enemy
---@field pointer_placement TooltipPlacement
---@field _layout layout.Layout
---@field _stats_layout layout.Layout
---@field _enemy_box ui.components.Box
local EnemyTooltip = class("components.EnemyTooltip", { super = Element })

---@param opts components.EnemyTooltip.Opts
function EnemyTooltip:init(opts)
  validate(opts, {
    box = "Box?",
    enemy_box = Box,
    enemy = "vibes.Enemy",
    z = "number?",
  })

  local box = opts.box or Box.new(Position.zero(), 400, 200)

  Element.init(self, box, {
    z = F.if_nil(opts.z, Z.TOOLTIP),
  })

  self.name = "EnemyTooltip"
  self.enemy = opts.enemy
  self.pointer_placement = TooltipPlacement.RIGHT
  self._enemy_box = opts.enemy_box

  self:set_hidden(true)
  self:set_opacity(0)
  self:set_interactable(false)

  self:_setup_layout()

  self:_setup_stats_rows()

  local x, _, w, h = self:get_geo()
  local ex, _, ew, eh = opts.enemy_box:geo()

  -- Position tooltip to the right of enemy by default
  self:set_y((-h / 2) + (eh / 2))

  -- Determine tooltip placement to ensure it's not off screen
  if ex - w < 0 then
    self:set_x(x + ew + 20)
    self.pointer_placement = TooltipPlacement.LEFT
  else
    self.pointer_placement = TooltipPlacement.RIGHT
    self:set_x(x - w - 20)
  end
end

function EnemyTooltip:_setup_layout()
  local _, _, w, h = self:get_geo()

  self._stats_layout = Layout.col {
    box = Box.new(Position.zero(), w, 50),
    els = {},
  }

  self._layout = Layout.new {
    name = "EnemyTooltip(Layout)",
    box = Box.new(Position.zero(), w, h),
    els = {
      Text.new {
        function()
          return {
            {
              text = self:_get_enemy_display_name(),
            },
          }
        end,
        box = Box.new(Position.zero(), w, 30),
        font = Asset.fonts.typography.h3,
        text_align = "left",
        padding = 15,
      },
      self._stats_layout,
    },
    flex = {
      justify_content = "center",
      gap = 10,
      align_items = "center",
      direction = "column",
    },
  }

  self:append_child(self._layout)
end

function EnemyTooltip:_setup_stats_rows()
  local _, _, w, _ = self:get_geo()
  local stats = self:_get_enemy_stats()

  local current_row = Layout.row {
    box = Box.new(Position.zero(), w * 0.90, 50),
    flex = { gap = 10 },
  }

  for idx, stat in ipairs(stats) do
    current_row:append_child(self:_create_stat_row(stat.icon, stat.value, idx))

    if idx % 5 == 0 or #stats == idx then
      self._stats_layout:append_child(current_row)
      current_row = Layout.row {
        box = Box.new(Position.zero(), w * 0.90, 50),
        flex = { gap = 10 },
      }
    end
  end

  local stats_h = (#self._stats_layout.children * 50)
  self._stats_layout:set_height(stats_h)
  self._layout:set_height(80 + stats_h)
  self:set_height(80 + stats_h)
end

function EnemyTooltip:_get_enemy_stats()
  return {
    { icon = IconType.HEART, value = self.enemy.max_health },
    { icon = IconType.SPEED, value = self.enemy:get_speed() },
    { icon = IconType.DAMAGE, value = self.enemy:get_damage() },
    { icon = IconType.GOLD, value = self.enemy.gold_reward },
    { icon = IconType.UPGRADE, value = self.enemy.xp_reward }, -- Using UPGRADE for XP
  }
end

function EnemyTooltip:_create_stat_row(icon_type, value, idx)
  local _, _, width, _ = self:get_geo()
  local bg_color = Colors.black:opacity(0.4 * self:get_opacity())
  if idx % 2 == 0 then
    bg_color = Colors.black:opacity(0.3 * self:get_opacity())
  end

  return Text.new {
    function()
      return {
        {
          color = Colors.white:get(),
          icon = Asset.icons[icon_type],
        },
        {
          text = tostring(value),
          color = Colors.white:get(),
        },
      }
    end,
    text_align = "center",
    font = Asset.fonts.typography.paragraph_sm,
    box = Box.new(Position.zero(), ((width * 0.90) - 16) / 5, 40),
    background = bg_color,
    rounded = 10,
    padding = 8,
    vertical_align = "center",
  }
end

function EnemyTooltip:_get_enemy_display_name()
  -- Convert enemy type to a more readable name
  local type_names = {
    [EnemyType.BAT] = "Bat",
    [EnemyType.BAT_ELITE] = "Elite Bat",
    [EnemyType.GOBLIN] = "Goblin",
    [EnemyType.MINE_GOBLIN] = "Mine Goblin",
    [EnemyType.ORC] = "Orc",
    [EnemyType.SNAIL] = "Snail",
    [EnemyType.WOLF] = "Wolf",
    [EnemyType.ORC_SHAMAN] = "Orc Shaman",
    [EnemyType.ORCA] = "Orca",
    [EnemyType.WYVERN] = "Wyvern",
    [EnemyType.KING] = "King",
  }

  return type_names[self.enemy.enemy_type] or self.enemy.enemy_type
end

function EnemyTooltip:enter_from_enemy()
  self:set_opacity(0)
  self:set_hidden(false)
  self:animate_style({ opacity = 1 }, { duration = 0.2 })
end

function EnemyTooltip:exit_enemy()
  self:animate_style(
    { opacity = 0 },
    { duration = 0.2, on_complete = function() self:set_hidden(true) end }
  )
end

function EnemyTooltip:_render()
  local x, y, w, h = self:get_geo()

  -- Enhanced background with better opacity
  love.graphics.setColor(Colors.gray:opacity(0.95 * self:get_opacity()))

  -- Background with pointer
  local union = function()
    love.graphics.push()
    if self.pointer_placement == TooltipPlacement.RIGHT then
      love.graphics.translate(x + w - 15, y + h / 2)
      love.graphics.rotate(0.80)
    elseif self.pointer_placement == TooltipPlacement.LEFT then
      love.graphics.translate(x + 15, y + h / 2)
      love.graphics.rotate(0.80)
    end

    love.graphics.rectangle("fill", -25, -35, 50, 50, 10, 10, 80)
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

  -- Enhanced border with better visibility
  love.graphics.setColor(Colors.white:opacity(0.6 * self:get_opacity()))
  love.graphics.setLineWidth(3) -- Increased line width for better visibility
  love.graphics.rectangle("line", x, y, w, h, 20, 20, 80)

  love.graphics.setColor(1, 1, 1, 1)
end

function EnemyTooltip:_update(_dt) end

return EnemyTooltip
