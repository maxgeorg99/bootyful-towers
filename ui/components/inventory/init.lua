local ButtonElement = require "ui.elements.button"
local Container = require "ui.components.container"
local Text = require "ui.components.text"

---@class (exact) ui.components.Inventory.Opts
---@field box ui.components.Box
---@field z? number

---@generic T
---@class ui.inventory.Containter<T> : Element, { children: T[] }

---@class ui.components.Inventory : Element
---@field new fun(opts: ui.components.Inventory.Opts): ui.components.Inventory
---@field init fun(self: ui.components.Inventory, opts: ui.components.Inventory.Opts)
---@field name string
---@field box ui.components.Box
---@field gear_containers ui.inventory.Containter<components.GearContainer>
---@field slots ui.inventory.Containter<components.GearSlotBackground>
---@field inventory_slots ui.inventory.Containter<components.GearInventorySlot>
---@field _selected_gear gear.Gear?
---@field _gear_details_display component.Text?
---@field _gear_stats_display component.Text?
local Inventory = class("ui.components.Inventory", { super = Element })

-- Specialized sell button that extends the new button system
local SellButton =
  class("ui.components.inventory.SellButton", { super = ButtonElement })

function SellButton:init(opts)
  ButtonElement.init(self, {
    box = opts.box,
    label = "",
    on_click = opts.on_click,
    kind = "filled",
  })

  self.inventory = opts.inventory
end

function SellButton:_render()
  local x, y, width, height = self:get_geo()

  -- Draw background using parent render
  ButtonElement._render(self)

  -- Custom label based on selection state
  local label_text
  if not self.inventory._selected_gear then
    label_text = "Select Gear to Sell"
  else
    local gear = self.inventory._selected_gear
    local sell_price = self.inventory:_calculate_sell_price(gear)
    label_text = string.format("Sell for %d Gold", sell_price)
  end

  -- Draw the text
  love.graphics.setFont(Asset.fonts.typography.h5)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.printf(label_text, x, y + (height / 2) - 10, width, "center")
end

---@param opts ui.components.Inventory.Opts
function Inventory:init(opts)
  Element.init(self, opts.box, {
    name = "Inventory",
    z = F.if_nil(opts.z, Z.INVENTORY_BASE),
  })

  local _, _, w, h = self:get_geo()
  self:append_child(require "ui.elements.hud"())

  -- Create containers with proper Z-indexes
  self.slots = Container.new {
    box = Box.new(Position.new(0, 0), w, h),
    z = Z.INVENTORY_SLOTS,
  }
  self:append_child(self.slots)

  self.gear_containers = Container.new {
    box = Box.new(Position.new(0, 0), w, h),
    z = Z.INVENTORY_GEAR_CONTAINERS,
  }
  self:append_child(self.gear_containers)

  -- Define slot dimensions - reduced from 192px to 64px for better proportions
  local slot_size = 96
  local gap = 16 -- Reduced gap to 16px for better spacing with smaller slots

  local line_one = 280
  local line_two = 398
  local line_three = 508
  local line_four = 620
  local line_inventory = 856

  -- Calculate positions based on armory background coordinates, centered for game display
  -- The armory background is 1920x1080, but we need to center it for the game window
  -- Head Slot (Top single slot): centered at x: 960 (center of 1920px image)
  local center_x = 960 - slot_size / 2 -- Center the slot
  self:_create_gear_slot {
    name = "hat",
    box = Box.new(Position.new(center_x, line_one), slot_size, slot_size),
    background = { 0.8, 0.6, 0.4, 0.8 },
    gear_kind = GearKind.HAT,
    gear_slot = GearSlot.HAT,
  }

  -- Chest Row (3 slots): centered around x: 960
  local chest_left_x = center_x - slot_size - gap
  local chest_right_x = center_x + slot_size + gap
  self:_create_gear_slot {
    name = "ring_left",
    box = Box.new(Position.new(chest_left_x, line_two), slot_size, slot_size),
    background = { 0.8, 0.8, 0.4, 0.8 },
    gear_kind = GearKind.RING,
    gear_slot = GearSlot.RING_LEFT,
  }

  self:_create_gear_slot {
    name = "necklace",
    box = Box.new(Position.new(center_x, line_two), slot_size, slot_size),
    background = { 0.8, 0.8, 0.4, 0.8 },
    gear_kind = GearKind.NECKLACE,
    gear_slot = GearSlot.NECKLACE,
  }

  self:_create_gear_slot {
    name = "ring_right",
    box = Box.new(Position.new(chest_right_x, line_two), slot_size, slot_size),
    background = { 0.8, 0.8, 0.4, 0.8 },
    gear_kind = GearKind.RING,
    gear_slot = GearSlot.RING_RIGHT,
  }

  -- Waist Row (3 slots): centered around x: 960
  self:_create_gear_slot {
    name = "tool_left",
    box = Box.new(Position.new(chest_left_x, line_three), slot_size, slot_size),
    background = { 0.6, 0.4, 0.8, 0.8 },
    gear_kind = GearKind.TOOL,
    gear_slot = GearSlot.TOOL_LEFT,
  }

  self:_create_gear_slot {
    name = "shirt",
    box = Box.new(Position.new(center_x, line_three), slot_size, slot_size),
    background = { 0.4, 0.8, 0.6, 0.8 },
    gear_kind = GearKind.SHIRT,
    gear_slot = GearSlot.SHIRT,
  }

  self:_create_gear_slot {
    name = "tool_right",
    box = Box.new(
      Position.new(chest_right_x, line_three),
      slot_size,
      slot_size
    ),
    background = { 0.6, 0.4, 0.8, 0.8 },
    gear_kind = GearKind.TOOL,
    gear_slot = GearSlot.TOOL_RIGHT,
  }

  -- Legs Row (2 slots): centered around x: 960
  local legs_left_x = center_x - (slot_size + gap) / 2
  local legs_right_x = center_x + (slot_size + gap) / 2
  self:_create_gear_slot {
    name = "pants",
    box = Box.new(Position.new(legs_left_x, line_four), slot_size, slot_size),
    background = { 0.4, 0.8, 0.6, 0.8 },
    gear_kind = GearKind.PANTS,
    gear_slot = GearSlot.PANTS,
  }

  self:_create_gear_slot {
    name = "shoes",
    box = Box.new(Position.new(legs_right_x, line_four), slot_size, slot_size),
    background = { 0.4, 0.8, 0.6, 0.8 },
    gear_kind = GearKind.SHOES,
    gear_slot = GearSlot.SHOES,
  }

  -- Bottom section: General inventory slots (4 slots in a row matching shelf)
  -- Shelf Slots: reduced from 160px to 48px for better proportions
  local shelf_center_x = 745
  local shelf_center_y = 785
  local shelf_gap = 16

  local inventory_elements = {}

  for i = 1, 4 do
    local slot
    if i == 1 then
      slot = GearSlot.INVENTORY_ONE
    elseif i == 2 then
      slot = GearSlot.INVENTORY_TWO
    elseif i == 3 then
      slot = GearSlot.INVENTORY_THREE
    elseif i == 4 then
      slot = GearSlot.INVENTORY_FOUR
    end

    local pos = { x = shelf_center_x, y = shelf_center_y }
    table.insert(
      inventory_elements,
      self:_create_inventory_slot(
        "inventory_" .. i,
        pos.x + (i - 1) * (slot_size + shelf_gap),
        pos.y,
        slot_size,
        slot_size,
        { 0.5, 0.5, 0.5, 0.8 },
        slot
      )
    )
  end

  ---@diagnostic disable-next-line
  self.inventory_slots = Layout.row {
    name = "InventorySlots",
    box = Box.fullscreen(),
    els = inventory_elements,
    z = Z.INVENTORY_INVENTORY_SLOTS,
    flex = {
      direction = "row",
      justify_content = "flex-start",
      align_items = "center",
      gap = 0, -- No gap since we're using absolute positioning
    },
  }

  self:append_child(self.inventory_slots)

  for _, gear in ipairs(State.gear_manager:get_active_gear()) do
    if self:_get_child_by_gear_slot(gear.slot) then
      local container = self:_create_gear_item {
        name = gear.name,
        gear = gear,
        container = self:_get_child_by_gear_slot(gear.slot),
        z = Z.GEAR_ACTIVE_CONTAINERS,
      }
      self.gear_containers:append_child(container)
    end
  end

  -- Add gear details display
  self:_create_gear_details_display(w, h)

  -- Add gear stats display on the left
  self:_create_gear_stats_display(w, h)

  -- Add sell functionality
  self:_create_sell_button(w, h)
end

--- Create gear details display on the right side of inventory
---@param w number
---@param h number
function Inventory:_create_gear_details_display(w, h)
  local details_width = 350
  local details_height = 500
  local details_x = w / 2 + details_width -- Closer to inventory
  local details_y = h * 0.45

  self._gear_details_display = Text.new {
    function()
      if not self._selected_gear then
        return "=== GEAR DETAILS ===\n\nClick on gear to see details"
      end

      local gear = self._selected_gear
      if not gear then
        return "=== GEAR DETAILS ===\n\nClick on gear to see details"
      end

      local lines = { "=== GEAR DETAILS ===" }
      table.insert(lines, "")
      table.insert(lines, string.format("Name: %s", gear.name or "Unknown"))
      table.insert(lines, string.format("Type: %s", gear.kind or "Unknown"))
      table.insert(lines, "")
      table.insert(lines, "Description:")

      -- Handle description (can be table or string)
      if gear.description then
        if type(gear.description) == "table" then
          for _, desc_line in ipairs(gear.description) do
            if desc_line then
              table.insert(lines, tostring(desc_line))
            end
          end
        else
          table.insert(lines, tostring(gear.description))
        end
      else
        table.insert(lines, "No description available")
      end

      return table.concat(lines, "\n")
    end,
    text_align = "left",
    vertical_align = "top",
    color = Colors.white:get(),
    font = Asset.fonts.typography.paragraph_md,
    box = Box.new(
      Position.new(details_x, details_y),
      details_width,
      details_height
    ),
    background = Colors.black:opacity(0.3), -- Semi-transparent background
    padding = 10,
  }

  self:append_child(self._gear_details_display)
end

--- Create gear stats display on the right side above gear details
---@param w number
---@param h number
function Inventory:_create_gear_stats_display(w, h)
  local stats_width = 350 -- Match details width for consistency
  local stats_height = 200 -- Smaller height since it's above details
  local stats_x = w / 2 + stats_width -- Closer to inventory
  local stats_y = h * 0.25

  self._gear_stats_display = Text.new {
    function()
      local stats = self:_calculate_gear_stats()
      local lines = { "=== EQUIPPED GEAR STATS ===" }
      table.insert(lines, "")

      if #stats == 0 then
        table.insert(lines, "No gear equipped")
        return table.concat(lines, "\n")
      end

      for _, stat in ipairs(stats) do
        table.insert(lines, stat)
      end

      return table.concat(lines, "\n")
    end,
    text_align = "left",
    vertical_align = "top",
    color = Colors.white:get(),
    font = Asset.fonts.typography.paragraph_md,
    box = Box.new(Position.new(stats_x, stats_y), stats_width, stats_height),
    background = Colors.black:opacity(0.3), -- Semi-transparent background
    padding = 10,
  }

  self:append_child(self._gear_stats_display)
end

--- Create sell button below gear details
---@param w number
---@param h number
function Inventory:_create_sell_button(w, h)
  local button_width = 200
  local button_height = 50
  local button_x = w / 2 + 350 -- Right side, below details
  local button_y = h * 0.75

  self._sell_button = SellButton.new {
    box = Box.new(
      Position.new(button_x, button_y),
      button_width,
      button_height
    ),
    on_click = function()
      if not self._selected_gear then
        return UIAction.HANDLED
      end

      self:_sell_selected_gear()
      return UIAction.HANDLED
    end,
    inventory = self,
  }

  self:append_child(self._sell_button)
end

--- Calculate aggregated gear stats from equipped gear
---@return string[]
function Inventory:_calculate_gear_stats()
  local stats = {}
  local stat_totals = {}

  -- Initialize stat totals
  for _, field in pairs(TowerStatField) do
    stat_totals[field] = {
      add_base = 0,
      add_mult = 0,
      mul_mult = 1,
    }
  end

  -- Aggregate stats from gear in equipped slots only (not inventory slots)
  for slot, gear in pairs(State.gear_manager._gear_slots) do
    -- Skip inventory slots - only count equipped gear
    if
      slot ~= GearSlot.INVENTORY_ONE
      and slot ~= GearSlot.INVENTORY_TWO
      and slot ~= GearSlot.INVENTORY_THREE
      and slot ~= GearSlot.INVENTORY_FOUR
    then
      -- Create a dummy tower for gear stat calculation
      local dummy_tower = { position = Position.new(0, 0) }
      if gear:is_active_on_tower(dummy_tower) then
        local operations = gear:get_tower_operations(dummy_tower)
        for _, operation in ipairs(operations) do
          local field = operation.field
          local op = operation.operation

          if op.kind == StatOperationKind.ADD_BASE then
            stat_totals[field].add_base = stat_totals[field].add_base + op.value
          elseif op.kind == StatOperationKind.ADD_MULT then
            stat_totals[field].add_mult = stat_totals[field].add_mult + op.value
          elseif op.kind == StatOperationKind.MUL_MULT then
            stat_totals[field].mul_mult = stat_totals[field].mul_mult * op.value
          end
        end
      end
    end
  end

  -- Format stats similar to range.lua
  for field, totals in pairs(stat_totals) do
    local has_effect = false
    local stat_line = ""

    if totals.add_base ~= 0 then
      stat_line = stat_line .. string.format("{+%s}", totals.add_base)
      has_effect = true
    end

    if totals.add_mult ~= 0 then
      if stat_line ~= "" then
        stat_line = stat_line .. " "
      end
      stat_line = stat_line
        .. string.format("{+%s%%}", math.floor(totals.add_mult * 100))
      has_effect = true
    end

    if totals.mul_mult ~= 1 then
      if stat_line ~= "" then
        stat_line = stat_line .. " "
      end
      stat_line = stat_line .. string.format("{x%s}", totals.mul_mult)
      has_effect = true
    end

    if has_effect then
      table.insert(stats, string.format("{%s:%s}", field, stat_line))
    end
  end

  return stats
end

--- Calculate sell price for a gear item based on its rarity
---@param gear gear.Gear?
---@return number
function Inventory:_calculate_sell_price(gear)
  if not gear then
    return 0
  end

  -- Base prices by rarity
  local rarity_prices = {
    [Rarity.COMMON] = 10,
    [Rarity.UNCOMMON] = 25,
    [Rarity.RARE] = 75,
    [Rarity.EPIC] = 200,
    [Rarity.LEGENDARY] = 500,
  }

  return gear:get_selling_price(rarity_prices[gear.rarity] or 10)
end

--- Sell the currently selected gear
function Inventory:_sell_selected_gear()
  local gear = self._selected_gear
  if not gear then
    return
  end

  local sell_price = self:_calculate_sell_price(gear)

  -- Add gold to player
  State.player:gain_gold(sell_price)

  -- Remove gear from inventory/manager
  local slot = self:_find_gear_for_slottable(gear)
  if slot then
    slot:remove_gear()
    State.gear_manager:remove_gear(slot.gear_slot)

    -- Remove gear container from UI
    local container = self:_find_gear_container_for_gear(gear)
    if container then
      container:remove_from_parent()
      -- Remove from gear_containers list
      for i, gc in ipairs(self.gear_containers.children) do
        if gc == container then
          table.remove(self.gear_containers.children, i)
          break
        end
      end
    end
  end

  -- Clear selection and show feedback
  self._selected_gear = nil

  -- Create user message about the sale
  UI:create_user_message(
    string.format("Sold %s for %d gold!", gear.name, sell_price)
  )
end

--- Update selected gear for details display
---@param gear gear.Gear?
function Inventory:set_selected_gear(gear) self._selected_gear = gear end

---@param gear_slot GearSlot
function Inventory:_get_child_by_gear_slot(gear_slot)
  for _, slot in ipairs(self.slots.children) do
    ---@cast slot components.GearSlotBackground
    if slot.gear_slot == gear_slot then
      return slot
    end
  end

  for _, slot in ipairs(self.inventory_slots.children) do
    ---@cast slot components.GearInventorySlot
    if slot.gear_slot == gear_slot then
      return slot
    end
  end
end

---@param name string
---@param x number
---@param y number
---@param width number
---@param height number
---@param color number[]
---@param slot GearSlot
function Inventory:_create_inventory_slot(
  name,
  x,
  y,
  width,
  height,
  color,
  slot
)
  -- Something
  local GearInventorySlotComponent =
    require "ui.components.inventory.gear-slot-inventory"
  return GearInventorySlotComponent.new {
    name = name,
    box = Box.new(Position.new(x, y), width, height),
    gear_slot = slot,
    background = Colors.blue,
    z = Z.INVENTORY_INVENTORY_SLOTS,
  }
end

---@class Inventory.CreateGearSlotOpts
---@field name string
---@field box ui.components.Box
---@field background table|nil
---@field gear_kind GearKind
---@field gear_slot GearSlot

---@param opts Inventory.CreateGearSlotOpts
---@return components.GearSlotBackground
function Inventory:_create_gear_slot(opts)
  validate(opts, {
    name = "string",
    box = Box,
    background = Optional { "number[]" },
    gear_kind = GearKind,
    gear_slot = GearSlot,
  })

  local GearSlotBackgroundComponent =
    require "ui.components.inventory.gear-slot-background"

  local container = GearSlotBackgroundComponent.new {
    name = opts.name,
    box = opts.box,
    gear_kind = opts.gear_kind,
    gear_slot = opts.gear_slot,
    background = opts.background or { 0.3, 0.3, 0.3, 0.8 }, -- Default gray background
    z = Z.GEAR_SLOT_BACKGROUND,
  }
  self.slots:append_child(container)

  return container
end

---@class Inventory.CreateGearItemOpts
---@field name string
---@field gear gear.Gear
---@field container gear.Slottable
---@field z? number

---@param opts Inventory.CreateGearItemOpts
---@return components.GearContainer
function Inventory:_create_gear_item(opts)
  local GearContainer = require "ui.components.inventory.gear-container"

  print(
    "creating gear item",
    opts.name,
    "for",
    opts.container.name,
    tostring(opts.container:get_box())
  )

  local item = GearContainer.new {
    name = opts.name,
    gear = opts.gear,
    container = opts.container,

    -- Add click handler to show gear details
    on_click = function(gear_container)
      self:set_selected_gear(gear_container.gear)
      return UIAction.HANDLED
    end,

    ---@param gear_container components.GearContainer
    ---@param _evt ui.components.UIDragStartEvent
    on_drag_start = function(gear_container, _evt)
      local home = self:_find_gear_for_slottable(gear_container.gear)
      self:_for_each_slottable(function(slot)
        ---@cast slot gear.Slottable
        if
          slot:can_assign_gear(gear_container.gear)
          and (not slot.gear or home:can_assign_gear(slot.gear))
        then
          slot:_mark_selectable()
        else
          slot:_reset_selectable()
        end
      end)
    end,

    ---@param gear_container components.GearContainer
    ---@param evt ui.components.UIDragEndEvent
    on_drag_end = function(gear_container, evt)
      self:_for_each_slottable(function(slot)
        ---@cast slot gear.Slottable
        slot:_reset_selectable()
      end)

      ---@type gear.Slottable[]
      local valid_targets = {}
      for _, slot in ipairs(self.slots.children) do
        ---@cast slot components.GearSlotBackground

        if slot:can_assign_gear(gear_container.gear) then
          table.insert(valid_targets, slot)
        end
      end

      table.list_extend(valid_targets, self.inventory_slots.children)

      local home = self:_find_gear_for_slottable(gear_container.gear)
      for _, slot in ipairs(valid_targets) do
        if slot:get_box():contains(evt.x, evt.y) then
          if self:_swap_gear_in_containers(home, slot) then
            return
          end
        end
      end

      -- Reset the item's location
      gear_container:animate_to_absolute_position(
        home:get_pos(),
        { duration = 0.2 }
      )
    end,
    z = opts.z or Z.MAX, -- Use provided Z or fallback to max
  }
  self.gear_containers:append_child(item)

  opts.container:assign_gear(item.gear)

  return item
end

---@alias gear.Slottable components.GearSlotBackground | components.GearInventorySlot

---@param left gear.Slottable
---@param right gear.Slottable
function Inventory:_swap_gear_in_containers(left, right)
  local left_gear = left.gear
  local right_gear = right.gear

  if left_gear == right_gear then
    return false
  end

  if left_gear and not right:can_assign_gear(left_gear) then
    return false
  end

  if right_gear and not left:can_assign_gear(right_gear) then
    return false
  end

  local right_container
  if right_gear then
    right_container = self:_find_gear_container_for_gear(right_gear)
  end

  local left_container
  if left_gear then
    left_container = self:_find_gear_container_for_gear(left_gear)
  end

  -- Remove gear from both slots (UI and gear manager)
  right:remove_gear()
  left:remove_gear()

  -- Remove gear from gear manager slots
  if right_gear then
    State.gear_manager:remove_gear(right.gear_slot)
  end
  if left_gear then
    State.gear_manager:remove_gear(left.gear_slot)
  end

  -- Reassign gear to new slots (UI and gear manager)
  if right_gear then
    left:assign_gear(right_gear)
    State.gear_manager:assign_gear_to_slot(right_gear, left.gear_slot)
    right_container:animate_to_absolute_position(
      left:get_pos(),
      { duration = 0.2 }
    )
    -- Update the container reference to point to the new slot
    right_container.container = left
  end

  if left_gear then
    right:assign_gear(left_gear)
    State.gear_manager:assign_gear_to_slot(left_gear, right.gear_slot)
    left_container:animate_to_absolute_position(
      right:get_pos(),
      { duration = 0.2 }
    )
    -- Update the container reference to point to the new slot
    left_container.container = right
  end

  return true
end

---@param gear gear.Gear
---@return gear.Slottable
function Inventory:_find_gear_for_slottable(gear)
  for _, slot in ipairs(self.slots.children) do
    ---@cast slot components.GearSlotBackground
    if slot.gear == gear then
      return slot
    end
  end

  for _, slot in ipairs(self.inventory_slots.children) do
    ---@cast slot components.GearInventorySlot
    if slot.gear == gear then
      return slot
    end
  end

  error "Gear not found in any slot"
end

---@param gear gear.Gear
---@return components.GearContainer
function Inventory:_find_gear_container_for_gear(gear)
  for _, container in ipairs(self.gear_containers.children) do
    ---@cast container components.GearContainer
    if container.gear == gear then
      return container
    end
  end

  error "Gear container not found"
end

function Inventory:_for_each_slottable(fn)
  for _, slot in ipairs(self.slots.children) do
    fn(slot)
  end
  for _, slot in ipairs(self.inventory_slots.children) do
    fn(slot)
  end
end

function Inventory:_update(dt) end

function Inventory:_render() end

return Inventory
