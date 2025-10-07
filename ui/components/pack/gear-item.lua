local ScaledImage = require "ui.components.scaled-img"
local Text = require "ui.components.text"

---@class components.GearItem.Opts
---@field box ui.components.Box
---@field gear gear.Gear
---@field on_click? fun(): UIAction
---@field on_selection_change? fun(gear_item: components.GearItemElement, selected: boolean)
---@field on_gear_added? fun(gear: gear.Gear): nil
---@field z? number
---@field inventory? ui.components.Inventory
---@field gear_selection? components.GearSelection

---@class (exact) components.GearItemElement : Element
---@field new fun(opts: components.GearItem.Opts): components.GearItemElement
---@field init fun(self: components.GearItemElement, opts: components.GearItem.Opts)
---@field gear gear.Gear
---@field _is_selected boolean
---@field _on_selection_change? fun(gear_item: components.GearItemElement, selected: boolean)
---@field _on_gear_added? fun(gear: gear.Gear): nil
---@field _inventory? ui.components.Inventory
---@field _gear_selection? components.GearSelection
---@field _original_position vibes.Position
---@field set_selected fun(self: components.GearItemElement, selected: boolean)
---@field is_selected fun(self: components.GearItemElement): boolean
---@field toggle_selection fun(self: components.GearItemElement)
---@field _on_click? fun(): UIAction
local GearItem = class("components.GearItemElement", { super = Element })

---@param opts components.GearItem.Opts
function GearItem:init(opts)
  validate(opts, {
    box = "ui.components.Box",
    gear = "table", -- gear.Gear
    on_click = "function?",
    on_selection_change = "function?",
    on_gear_added = "function?",
    inventory = Optional { "table" }, -- ui.components.Inventory
    gear_selection = Optional { "table" }, -- components.GearSelection
  })

  Element.init(self, opts.box, {
    name = "GearItemElement",
    interactable = true,
    z = opts.z or Z.SHOP_PACK_OVERLAY,
    draggable = true,
  })

  self.gear = opts.gear
  self._on_selection_change = opts.on_selection_change
  self._on_gear_added = opts.on_gear_added
  self._inventory = opts.inventory
  self._gear_selection = opts.gear_selection
  self._is_selected = false

  self._on_click = opts.on_click

  -- Store original position for drag reset
  self._original_position = self:get_pos()

  self:_setup_layout()
end

function GearItem:_setup_layout()
  local _, _, w, h = self:get_geo()

  -- Create a layout showing gear information differently than cards
  local layout = Layout.new {
    name = "GearItem",
    box = Box.new(Position.zero(), w, h),
    els = {
      -- Gear icon/texture area
      Layout.new {
        name = "GearIcon",
        box = Box.new(Position.zero(), w, h * 0.6),
        els = {
          ScaledImage.new {
            texture = self.gear.texture,
            box = Box.new(Position.zero(), w * 0.782, h * 0.48875),
            scale_style = "fit", -- Fit the texture within the bounds
          },
        },
        flex = {
          direction = "column",
          justify_content = "center",
          align_items = "center",
        },
      },
      -- Gear info area
      Layout.new {
        name = "GearInfo",
        box = Box.new(Position.zero(), w, h * 0.4),
        els = {
          Text.new {
            function() return self.gear.name end,
            text_align = "center",
            color = Colors.white:get(),
            font = Asset.fonts.typography.paragraph_md,
            box = Box.new(Position.zero(), w, 25),
          },
          Text.new {
            function() return string.upper(self.gear.kind) end,
            text_align = "center",
            color = Colors.gray:get(),
            font = Asset.fonts.typography.paragraph_sm,
            box = Box.new(Position.zero(), w, 20),
          },
          -- TODO: Add gear description if needed
        },
        flex = {
          direction = "column",
          justify_content = "start",
          align_items = "center",
          gap = 5,
        },
      },
    },
    flex = {
      direction = "column",
      justify_content = "start",
      align_items = "center",
    },
  }

  self:append_child(layout)
end

--- Get a color for the gear based on its kind
---@return number[]
function GearItem:_get_gear_color()
  local kind_colors = {
    [GearKind.HAT] = Colors.purple:get(),
    [GearKind.SHIRT] = Colors.blue:get(),
    [GearKind.PANTS] = Colors.green:get(),
    [GearKind.SHOES] = Colors.brown:get(),
    [GearKind.NECKLACE] = Colors.yellow:get(),
    [GearKind.RING] = Colors.orange:get(),
    [GearKind.TOOL] = Colors.red:get(),
  }

  return kind_colors[self.gear.kind] or Colors.gray:get()
end

--- Set the selection state of the gear item
---@param selected boolean
function GearItem:set_selected(selected)
  if self._is_selected == selected then
    return
  end

  self._is_selected = selected

  -- Update visual state - different from cards
  if selected then
    self:set_z(self:get_z() + 1)
    self:animate_style({ scale = 1.05 }, { duration = 0.1 })
    -- TODO: Add visual selection indicator (border/glow) when UI system supports it
  else
    self:set_z(self:get_z() - 1)
    self:animate_style({ scale = 1 }, { duration = 0.1 })
  end

  -- Notify parent component of selection change
  if self._on_selection_change then
    self._on_selection_change(self, selected)
  end
end

--- Check if the gear item is currently selected
---@return boolean
function GearItem:is_selected() return self._is_selected end

--- Toggle the selection state of the gear item
function GearItem:toggle_selection() self:set_selected(not self._is_selected) end

--- Override the click handler to manage selection
function GearItem:_click()
  -- Handle our selection logic first
  self:toggle_selection()

  -- Then call the parent's click handler if it exists
  if self._on_click then
    return self:_on_click()
  end

  return UIAction.HANDLED
end

function GearItem:_render() end

--- Drag start handler
function GearItem:_drag_start(evt)
  logger.info(
    "Starting drag for gear: %s at mouse (%d,%d), item pos (%d,%d)",
    self.gear.name,
    evt.x,
    evt.y,
    self:get_pos().x,
    self:get_pos().y
  )

  -- Mark all compatible inventory slots as selectable
  if self._inventory then
    self._inventory:_for_each_slottable(function(slot)
      ---@cast slot gear.Slottable
      if slot:can_assign_gear(self.gear) and not slot.gear then
        slot:_mark_selectable()
      else
        slot:_reset_selectable()
      end
    end)
  end
end

--- Drag end handler
function GearItem:_drag_end(evt)
  logger.info(
    "Ending drag for gear: %s at %d, %d",
    self.gear.name,
    evt.x,
    evt.y
  )

  -- Reset all slot selection states
  if self._inventory then
    self._inventory:_for_each_slottable(function(slot)
      ---@cast slot gear.Slottable
      slot:_reset_selectable()
    end)
  end

  local dropped = false

  -- Check if we dropped on a valid inventory slot
  if self._inventory then
    -- Get all valid drop targets (empty slots that can accept this gear)
    ---@type gear.Slottable[]
    local valid_targets = {}

    -- Check equipped gear slots
    for _, slot in ipairs(self._inventory.slots.children) do
      ---@cast slot components.GearSlotBackground
      if slot:can_assign_gear(self.gear) and not slot.gear then
        table.insert(valid_targets, slot)
      end
    end

    -- Check inventory slots
    for _, slot in ipairs(self._inventory.inventory_slots.children) do
      ---@cast slot components.GearInventorySlot
      if slot:can_assign_gear(self.gear) and not slot.gear then
        table.insert(valid_targets, slot)
      end
    end

    -- Check if we dropped on any valid target
    for _, slot in ipairs(valid_targets) do
      local slot_box = slot:get_box()
      logger.info(
        "Checking slot %s: box=(%d,%d,%d,%d), mouse=(%d,%d)",
        slot.gear_slot or "unknown",
        slot_box.position.x,
        slot_box.position.y,
        slot_box.width,
        slot_box.height,
        evt.x,
        evt.y
      )

      if slot_box:contains(evt.x, evt.y) then
        -- Successfully dropped on a valid slot
        local success = true

        -- Wrap gear assignment in error handling
        local gear_assignment_success, gear_assignment_error = pcall(
          function()
            State.gear_manager:assign_gear_to_slot(self.gear, slot.gear_slot)
          end
        )

        if not gear_assignment_success then
          logger.error(
            "Failed to assign gear to slot: %s",
            gear_assignment_error
          )
          success = false
        end

        local gear_container = nil
        if success then
          -- Create a gear container using the inventory's existing method
          local container_success, container_error = pcall(
            function()
              gear_container = self._inventory:_create_gear_item {
                name = self.gear.name,
                gear = self.gear,
                container = slot,
                z = Z.INVENTORY_GEAR_CONTAINERS,
              }
            end
          )

          if not container_success then
            logger.error("Failed to create gear container: %s", container_error)
            success = false
          end
        end

        if success then
          -- Hide this gear item since it's now represented by the gear container
          self:set_hidden(true)

          -- Notify the gear selection that gear was successfully added
          if self._gear_selection then
            self._gear_selection:_on_gear_successfully_added(self.gear)
          end

          -- Call the custom callback if provided
          if self._on_gear_added then
            self._on_gear_added(self.gear)
          end

          dropped = true
          logger.info(
            "Successfully added gear %s to slot %s",
            self.gear.name,
            slot.gear_slot
          )
        else
          logger.warn(
            "Failed to add gear %s to slot %s",
            self.gear.name,
            slot.gear_slot
          )
        end

        break
      end
    end
  end

  -- If not dropped successfully, return to original position
  if not dropped then
    self:animate_to_absolute_position(
      self._original_position,
      { duration = 0.2 }
    )
  end
end

function GearItem:__tostring()
  return string.format(
    "GearItemElement(%s [%s], selected=%s)",
    self.gear.name,
    self.gear.kind,
    self._is_selected
  )
end

return GearItem
