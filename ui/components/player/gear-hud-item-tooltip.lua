-- TODO: This file should be abstracted to be a tooltip that makes a bit more
-- sense. I don't really understand the tooltip stuff we have going on
-- beforehand. I don't thin we need to special case tooltips as elements.

local Text = require "ui.components.text"

---@class components.GearHudItemTooltip.Opts
---@field gear gear.Gear
---@field el Element
---@field placement "NEAR_ELEMENT" | "CENTER_SCREEN" | "WINDOW_TOP_CENTER" | "BENEATH_ELEMENT"
---@field width number
---@field height number

---@class components.GearHudItemTooltip : Element
---@field new fun(opts: components.GearHudItemTooltip.Opts): components.GearHudItemTooltip
---@field init fun(self: components.GearHudItemTooltip, opts: components.GearHudItemTooltip.Opts)
local GearHudItemTooltip =
  class("ui.components.player.GearHudItemTooltip", { super = Element })

local PADDING = 8

---@param self ui.components.Box
---@param el Element
---@param placement "NEAR_ELEMENT" | "CENTER_SCREEN" | "WINDOW_TOP_CENTER" | "BENEATH_ELEMENT"
---@return vibes.Position
local calculate_box = function(self, el, placement)
  local el_x, el_y, el_w, el_h = el:get_geo()

  if placement == "CENTER_SCREEN" then
    local _, _, self_w, self_h = self:geo()
    local cx = el_w / 2
    local cy = el_h / 2
    return Position.new(cx - self_w / 2, cy - self_h / 2)
  elseif placement == "WINDOW_TOP_CENTER" then
    local _, _, self_w, self_h = self:geo()
    local cx = Config.window_size.width / 2
    local cy = 35
    return Position.new(cx - self_w / 2, cy - self_h / 2)
  elseif placement == "NEAR_ELEMENT" then
    local _, _, self_w, self_h = self:geo()

    -- Try right side first
    local right_x = el_x + el_w + PADDING
    local middle_y = el_y + el_h / 2 - self_h / 2

    if
      right_x + self_w <= Config.window_size.width
      and middle_y >= 0
      and middle_y + self_h <= Config.window_size.height
    then
      return Position.new(right_x, middle_y)
    end

    -- Try left side
    local left_x = el_x - self_w - PADDING
    if
      left_x >= 0
      and middle_y >= 0
      and middle_y + self_h <= Config.window_size.height
    then
      return Position.new(left_x, middle_y)
    end

    -- Try above
    local above_y = el_y - self_h - PADDING
    local center_x = el_x + el_w / 2 - self_w / 2
    if
      above_y >= 0
      and center_x >= 0
      and center_x + self_w <= Config.window_size.width
    then
      return Position.new(center_x, above_y)
    end

    -- Try below
    local below_y = el_y + el_h + PADDING
    if
      below_y + self_h <= Config.window_size.height
      and center_x >= 0
      and center_x + self_w <= Config.window_size.width
    then
      return Position.new(center_x, below_y)
    end
  elseif placement == "BENEATH_ELEMENT" then
    local _, _, self_w, self_h = self:geo()

    -- Try below (centered)
    local center_x = el_x + el_w / 2 - self_w / 2
    local below_y = el_y + el_h + PADDING

    if
      center_x >= 0
      and center_x + self_w <= Config.window_size.width
      and below_y + self_h <= Config.window_size.height
    then
      return Position.new(center_x, below_y)
    end

    -- Try above (centered)
    local above_y = el_y - self_h - PADDING
    if
      center_x >= 0
      and center_x + self_w <= Config.window_size.width
      and above_y >= 0
    then
      return Position.new(center_x, above_y)
    end

    -- Try right side
    local right_x = el_x + el_w + PADDING
    local middle_y = el_y + el_h / 2 - self_h / 2

    if
      right_x + self_w <= Config.window_size.width
      and middle_y >= 0
      and middle_y + self_h <= Config.window_size.height
    then
      return Position.new(right_x, middle_y)
    end

    -- Try left side
    local left_x = el_x - self_w - PADDING
    if
      left_x >= 0
      and middle_y >= 0
      and middle_y + self_h <= Config.window_size.height
    then
      return Position.new(left_x, middle_y)
    end
  end

  -- Fallback: center of screen if nothing else works
  local _, _, self_w, self_h = self:geo()
  return Position.new(
    (Config.window_size.width - self_w) / 2,
    (Config.window_size.height - self_h) / 2
  )
end

function GearHudItemTooltip:init(opts)
  opts.placement = opts.placement or "NEAR_ELEMENT"
  local box = Box.new(Position.new(0, 0), opts.width, opts.height)
  box.position = calculate_box(box, opts.el, opts.placement)
  Element.init(self, box, {
    interactable = false, -- Tooltips should not interfere with interaction
  })

  self:set_hidden(true)
  self.gear = opts.gear

  self.text = Text.new {
    function() return self:_build_tooltip_content() end,

    box = Box.new(Position.zero(), opts.width, opts.height),
  }
  self:append_child(self.text)

  self.z = Z.TOOLTIP
  self.text.z = Z.TOOLTIP
end

--- Build comprehensive tooltip content with gear information
---@return ui.Text.Item[]
function GearHudItemTooltip:_build_tooltip_content()
  local content = {}

  -- Gear name with rarity color
  local rarity_color = self:_get_rarity_color()
  table.insert(content, {
    text = self.gear.name,
    color = rarity_color,
    font = Asset.fonts.insignia_18,
  })

  -- Gear kind and rarity
  table.insert(content, TextControl.NewLine)
  table.insert(content, {
    text = string.format("%s • %s", self.gear.kind, self.gear.rarity),
    color = Colors.gray,
    font = Asset.fonts.typography.paragraph_sm,
  })

  table.insert(content, TextControl.NewLine)
  table.insert(content, TextControl.NewLine)

  -- Description
  if self.gear.description then
    for _, desc_item in ipairs(self.gear.description) do
      table.insert(content, desc_item)
    end
  end

  -- Add stat effects if the gear affects towers or enemies
  local stat_effects = self:_get_stat_effects()
  if #stat_effects > 0 then
    table.insert(content, TextControl.NewLine)
    table.insert(content, TextControl.NewLine)
    table.insert(content, {
      text = "Effects:",
      color = Colors.gold,
      font = Asset.fonts.typography.paragraph_sm,
    })

    for _, effect in ipairs(stat_effects) do
      table.insert(content, TextControl.NewLine)
      table.insert(content, {
        text = "• " .. effect,
        color = Colors.light_gray,
        font = Asset.fonts.typography.paragraph_sm,
      })
    end
  end

  return content
end

--- Get the color associated with the gear's rarity
---@return number[]
function GearHudItemTooltip:_get_rarity_color()
  if self.gear.rarity == Rarity.COMMON then
    return Colors.white
  elseif self.gear.rarity == Rarity.UNCOMMON then
    return Colors.green
  elseif self.gear.rarity == Rarity.RARE then
    return Colors.blue
  elseif self.gear.rarity == Rarity.EPIC then
    return Colors.purple
  elseif self.gear.rarity == Rarity.LEGENDARY then
    return Colors.gold
  else
    return Colors.white
  end
end

--- Get a list of stat effects this gear provides
---@return string[]
function GearHudItemTooltip:_get_stat_effects()
  local effects = {}

  -- Check if gear affects towers
  if self.gear.is_active_on_tower and self.gear.get_tower_operations then
    -- Create a mock tower to test operations
    local mock_tower = { stats_base = {} }
    if self.gear:is_active_on_tower(mock_tower) then
      local operations = self.gear:get_tower_operations(mock_tower)
      for _, operation in ipairs(operations) do
        local effect_text = self:_format_tower_operation(operation)
        if effect_text then
          table.insert(effects, effect_text)
        end
      end
    end
  end

  -- Check if gear affects enemies
  if self.gear.is_active_on_enemy and self.gear.get_enemy_operations then
    -- Create a mock enemy to test operations
    local mock_enemy = { stats_base = {} }
    if self.gear:is_active_on_enemy(mock_enemy) then
      local operations = self.gear:get_enemy_operations(mock_enemy)
      for _, operation in ipairs(operations) do
        local effect_text = self:_format_enemy_operation(operation)
        if effect_text then
          table.insert(effects, effect_text)
        end
      end
    end
  end

  return effects
end

--- Format a tower stat operation into readable text
---@param operation tower.StatOperation
---@return string?
function GearHudItemTooltip:_format_tower_operation(operation)
  local field_name = self:_format_stat_field_name(operation.field)
  local op = operation.operation

  if op.kind == StatOperationKind.ADD_BASE then
    return string.format("+%g %s", op.value, field_name)
  elseif op.kind == StatOperationKind.ADD_MULT then
    return string.format("+%g%% %s", op.value * 100, field_name)
  elseif op.kind == StatOperationKind.MUL_MULT then
    local percent = (op.value - 1) * 100
    if percent > 0 then
      return string.format("+%g%% %s", percent, field_name)
    else
      return string.format("%g%% %s", percent, field_name)
    end
  end

  return nil
end

--- Format an enemy stat operation into readable text
---@param operation enemy.StatOperation
---@return string?
function GearHudItemTooltip:_format_enemy_operation(operation)
  local field_name = self:_format_stat_field_name(operation.field)
  local op = operation.operation

  if op.kind == StatOperationKind.ADD_BASE then
    return string.format("Enemies: +%g %s", op.value, field_name)
  elseif op.kind == StatOperationKind.ADD_MULT then
    return string.format("Enemies: +%g%% %s", op.value * 100, field_name)
  elseif op.kind == StatOperationKind.MUL_MULT then
    local percent = (op.value - 1) * 100
    if percent > 0 then
      return string.format("Enemies: +%g%% %s", percent, field_name)
    else
      return string.format("Enemies: %g%% %s", percent, field_name)
    end
  end

  return nil
end

--- Format stat field names into readable text
---@param field string
---@return string
function GearHudItemTooltip:_format_stat_field_name(field)
  -- Convert enum values to readable names
  local field_names = {
    [TowerStatField.DAMAGE] = "Damage",
    [TowerStatField.ATTACK_SPEED] = "Attack Speed",
    [TowerStatField.RANGE] = "Range",
    [TowerStatField.CRITICAL] = "Critical Multiplier",
    [TowerStatField.ENEMY_TARGETS] = "Target Count",
    [TowerStatField.AOE] = "AoE",
    [TowerStatField.DURABILITY] = "Durability",
    [EnemyStatField.DAMAGE] = "Damage",
    [EnemyStatField.SPEED] = "Speed",
    [EnemyStatField.SHIELD] = "Shield",
    [EnemyStatField.SHIELD_CAPACITY] = "Shield Capacity",
  }

  return field_names[field] or tostring(field)
end

--- Animation method for showing tooltip
function GearHudItemTooltip:enter_from_gear()
  self:set_opacity(0)
  self:set_hidden(false)
  self:animate_style({ opacity = 1 }, { duration = 0.2 })
end

--- Animation method for hiding tooltip
function GearHudItemTooltip:exit_gear()
  self:animate_style({ opacity = 0 }, {
    duration = 0.2,
    on_complete = function() self:set_hidden(true) end,
  })
end

function GearHudItemTooltip:_render()
  local x, y, w, h = self:get_geo()

  -- Use the same background style as other tooltips
  love.graphics.setColor(Colors.gray:opacity(0.95 * self:get_opacity()))
  love.graphics.rectangle("fill", x, y, w, h, 10, 10)

  -- Reset color
  love.graphics.setColor(1, 1, 1, 1)
end

return GearHudItemTooltip
