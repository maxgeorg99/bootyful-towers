local ButtonElement = require "ui.elements.button"
local Container = require "ui.components.container"
local GearItem = require "ui.components.pack.gear-item"
local Inventory = require "ui.components.inventory"
local ScaledImg = require "ui.components.scaled-img"
local Text = require "ui.components.text"

-- Layout constants - much bigger sizing to use full screen space
local GEAR_LIST_WIDTH = 500
local PADDING = 80
local GEAR_ITEM_HEIGHT = 100 -- Reduced for tighter grid spacing
local GEAR_ITEM_SPACING = 5
local INVENTORY_WIDTH = Config.window_size.width

-- Position gear list 250px from left
local gear_list_x = 250 -- Move 250px from left edge
local gear_size = 150

---@class (exact) components.GearSelection.Opts
---@field pack vibes.GearPack
---@field on_confirm fun(gear: gear.Gear)
---@field on_cancel fun()

---@class (exact) components.GearSelection : Element
---@field init fun(self: components.GearSelection, opts: components.GearSelection.Opts)
---@field new fun(opts: components.GearSelection.Opts): components.GearSelection
---@field pack vibes.GearPack
---@field _selected_gear gear.Gear?
---@field _on_confirm fun(gear: gear.Gear)
---@field _on_cancel fun()
---@field _inventory ui.components.Inventory
---@field _pack_items components.GearItemElement[]
---@field _selected_gear_display component.Text?
---@field _gear_container Element?
---@field _navigation component.Text?
---@field _page_indicator component.Text?
---@field _current_page number
---@field _total_pages number
---@field _content_start_x number
---@field _gear_list_origin number
local GearSelection = class("components.GearSelection", { super = Element })

function GearSelection:init(opts)
  validate(opts, {
    pack = "table", -- vibes.GearPack
    on_confirm = "function",
    on_cancel = "function",
  })

  Element.init(self, Box.fullscreen(), {
    z = Z.GEAR_SELECTION_OVERLAY,
    interactable = true, -- Make overlay interactable so we can handle clicks
  })

  self.pack = opts.pack

  self._on_confirm = opts.on_confirm
  self._on_cancel = opts.on_cancel

  self:_build_layout()
  self:_build_gear_list()
end

function GearSelection:_build_gear_list()
  for i, gear in ipairs(self.pack.gear) do
    local y_offset = (i - 1) * (gear_size + GEAR_ITEM_SPACING)
    local gear_item = GearItem.new {
      box = Box.new(Position.new(0, y_offset), gear_size, gear_size),
      gear = gear,
      z = Z.GEAR_ACTIVE_CONTAINERS,
      on_gear_added = function(added_gear)
        self:set_interactable(false)
        self:animate_style(
          { opacity = 0 },
          { duration = 1, on_complete = function() self._on_confirm(gear) end }
        )
        -- Timer.oneshot(1000, function() self._on_confirm(gear) end)
      end,
    }
    gear_item._inventory = self._inventory
    self._gear_container:append_child(gear_item)
  end
end

function GearSelection:_build_layout()
  local _, _, w, h = self:get_geo()

  -- Add armory background
  local armory_bg = ScaledImg.new {
    box = Box.new(Position.new(0, 0), w, h),
    texture = Asset.sprites.armory_background,
    scale_style = "stretch",
    z = Z.TROPHY_SELECTION_BACKGROUND,
  }
  self:append_child(armory_bg)

  self:_create_main_layout(w, h)
  self:_create_return_button(w, h)
  self:_create_debug_gear_info(w, h)
end

function GearSelection:_create_main_layout(w, h)
  -- Calculate vertical centering
  local title_height = 100 -- Space for title and instructions
  local nav_height = 80 -- Space for navigation controls at bottom
  local available_height = h - title_height - nav_height
  local inventory_height = 600 -- Desired inventory height

  local content_y = title_height + (available_height - inventory_height) / 2
  local content_height = inventory_height

  -- Calculate total width including gear list, inventory, and details (stats are now stacked above details)
  local details_width = 350 -- Details and stats share the same width on right side
  local gear_list_gap = PADDING
  local details_gap = 10
  local total_content_width = GEAR_LIST_WIDTH
    + gear_list_gap
    + Config.window_size.width
    + details_gap
    + details_width

  self._content_start_x = math.max(PADDING, (w - total_content_width) / 2)

  self._inventory = Inventory.new {
    box = Box.fullscreen(),
    z = Z.GEAR_SELECTION_INVENTORY,
  }
  self:append_child(self._inventory)

  self:_create_gear_list(content_y, content_height)
end

function GearSelection:_create_gear_list(content_y, content_height)
  self._pack_items = {}

  local gear_label = Text.new {
    function() return "Available Gear:" end,
    text_align = "left",
    color = Colors.yellow:get(),
    font = Asset.fonts.typography.h3,
    box = Box.new(
      Position.new(gear_list_x, content_y - 80 + 100),
      GEAR_LIST_WIDTH,
      80
    ), -- Move title down 100px
    z = Z.GEAR_SELECTION_UI,
  }
  self:append_child(gear_label)

  self._gear_list_origin = content_y
  self._gear_container = Container.new {
    box = Box.new(
      Position.new(100, 400), -- Start gear list 130px higher than content_y, then move down 100px
      GEAR_LIST_WIDTH,
      content_height + 130
    ),
    z = Z.INVENTORY_GEAR_CONTAINERS,
  }
  self:append_child(self._gear_container)
end

function GearSelection:_create_return_button(w, h)
  local return_button = ButtonElement.new {
    box = Box.new(Position.new(PADDING, h - 60 - PADDING), 240, 50),
    label = "Back To Shop",
    z = Z.GEAR_SELECTION_UI,
    on_click = function()
      self:_reset_slot_highlights()
      self._on_cancel()
    end,
  }
  self:append_child(return_button)
end

function GearSelection:_handle_item_clicked(gear)
  self._selected_gear = gear

  for _, item in ipairs(self._pack_items) do
    item:set_selected(item.gear == gear)
  end

  if self._inventory then
    self._inventory:set_selected_gear(gear)
    self:_reset_slot_highlights()
    self._inventory:_for_each_slottable(function(slot)
      if slot:can_assign_gear(gear) and not slot.gear then
        slot:_mark_selectable()
      elseif slot.gear == gear then
        slot:_mark_selectable()
      end
    end)
  end
end

function GearSelection:_reset_slot_highlights()
  if not self._inventory then
    return
  end

  self._inventory:_for_each_slottable(
    function(slot) slot:_reset_selectable() end
  )
end

function GearSelection:_create_debug_gear_info(w, h)
  -- Debug text box on the right side showing gear manager state
  local debug_x = w - 350 - PADDING -- 350px wide, positioned from right edge
  local debug_y = PADDING + 60 -- Below title
  local debug_width = 350
  local debug_height = 300 -- Smaller to make room for gear details

  if self:is_debug_mode() then
    local debug_text = Text.new {
      function()
        local lines = { "=== GEAR MANAGER DEBUG ===" }

        local active_gear = State.gear_manager:get_active_gear()
        table.insert(
          lines,
          string.format("Active Gear Count: %d", #active_gear)
        )
        table.insert(lines, "")

        -- Show equipped gear by slot using new table-based approach
        local gear_manager = State.gear_manager
        table.insert(lines, "EQUIPPED GEAR:")

        local equipped_slots = {
          { slot = GearSlot.HAT, name = "Hat" },
          { slot = GearSlot.SHIRT, name = "Shirt" },
          { slot = GearSlot.PANTS, name = "Pants" },
          { slot = GearSlot.SHOES, name = "Shoes" },
          { slot = GearSlot.NECKLACE, name = "Necklace" },
          { slot = GearSlot.RING_LEFT, name = "Ring L" },
          { slot = GearSlot.RING_RIGHT, name = "Ring R" },
          { slot = GearSlot.TOOL_LEFT, name = "Tool L" },
          { slot = GearSlot.TOOL_RIGHT, name = "Tool R" },
        }

        for _, slot_info in ipairs(equipped_slots) do
          local gear = gear_manager:get_gear(slot_info.slot)
          table.insert(
            lines,
            string.format(
              "%s: %s",
              slot_info.name,
              gear and gear.name or "None"
            )
          )
        end

        table.insert(lines, "")
        table.insert(lines, "INVENTORY:")

        local inventory_slots = {
          { slot = GearSlot.INVENTORY_ONE, name = "Slot 1" },
          { slot = GearSlot.INVENTORY_TWO, name = "Slot 2" },
          { slot = GearSlot.INVENTORY_THREE, name = "Slot 3" },
          { slot = GearSlot.INVENTORY_FOUR, name = "Slot 4" },
        }

        for _, slot_info in ipairs(inventory_slots) do
          local gear = gear_manager:get_gear(slot_info.slot)
          table.insert(
            lines,
            string.format(
              "%s: %s",
              slot_info.name,
              gear and gear.name or "Empty"
            )
          )
        end

        return table.concat(lines, "\n")
      end,
      text_align = "left",
      color = Colors.green:get(),
      font = Asset.fonts.typography.paragraph_sm,
      box = Box.new(Position.new(debug_x, debug_y), debug_width, debug_height),
      z = Z.GEAR_SELECTION_UI,
      background = { 0, 0, 0, 0.7 }, -- Semi-transparent background
      padding = 10,
    }
    self:append_child(debug_text)
  end
end

--- Called when gear is successfully added to inventory via drag-and-drop
---@param gear gear.Gear
function GearSelection:_on_gear_successfully_added(gear)
  if self._on_gear_added then
    self._on_gear_added(gear)
  end

  self:_reset_slot_highlights()
end

function GearSelection:_render() end

--- Handle clicks on the overlay background (outside content areas)
function GearSelection:_click(evt)
  -- Check if the click was outside the main content areas
  local gear_list_x = 0 -- Match the leftmost positioning
  local inventory_x = PADDING + GEAR_LIST_WIDTH + PADDING
  local content_y = 100
  local content_height = self:get_box().height - content_y - PADDING

  -- Define the main content areas
  local gear_list_box = Box.new(
    Position.new(gear_list_x, content_y),
    GEAR_LIST_WIDTH,
    content_height
  )

  local inventory_box = Box.new(
    Position.new(inventory_x, content_y + 120),
    INVENTORY_WIDTH,
    content_height - 120
  )

  -- Check if click was outside both content areas
  if
    not gear_list_box:contains(evt.x, evt.y)
    and not inventory_box:contains(evt.x, evt.y)
  then
    -- Click was on the background overlay - close the gear selection
    logger.info "Clicked outside gear selection content - closing"
    self._on_cancel()
    return UIAction.HANDLED
  end

  -- Click was handled by child elements
  return nil
end

return GearSelection
