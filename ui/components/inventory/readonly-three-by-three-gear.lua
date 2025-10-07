local Text = require "ui.components.text"
local TitleBox = require "ui.elements.title-box"

---@diagnostic disable: assign-type-mismatch

---@class ui.components.inventory.ReadOnlyThreeByThreeGear : Element
---@field new fun(opts: {}): ui.components.inventory.ReadOnlyThreeByThreeGear
---@field init fun(self: ui.components.inventory.ReadOnlyThreeByThreeGear, opts: {})
---@field texture vibes.Texture
---@field hovered_gear_slot GearSlot?
---@field gear_slot_elements ui.components.inventory.ReadOnlyThreeByThreeGear.GearSlotElement[]
---@field tooltip_title component.Text
---@field tooltip_description component.Text
---@field tooltip_box elements.TitleBox
---@field set_hovered_gear_slot fun(self: ui.components.inventory.ReadOnlyThreeByThreeGear, gear_slot: GearSlot)
---@field clear_hovered_gear fun(self: ui.components.inventory.ReadOnlyThreeByThreeGear)
---@field _create_gear_slot_elements fun(self: ui.components.inventory.ReadOnlyThreeByThreeGear)
---@field _create_tooltip fun(self: ui.components.inventory.ReadOnlyThreeByThreeGear)
---@field _update_tooltip_content fun(self: ui.components.inventory.ReadOnlyThreeByThreeGear, gear: gear.Gear)
local ReadOnlyThreeByThreeGear =
  class("ui.components.inventory.ReadOnlyThreeByThreeGear", { super = Element })

local TOP_LEFT = 72
local TOP_RIGHT = 820

local RECTANGLE = 72
local GAP = 4
local X_OFFSET = RECTANGLE + GAP
local Y_OFFSET = RECTANGLE + GAP

local TOOLTIP_WIDTH = 420
local TOOLTIP_HEIGHT = 240
local TOOLTIP_X = TOP_LEFT -- Align with gear grid left edge
local TOOLTIP_Y = TOP_RIGHT - TOOLTIP_HEIGHT - 20 -- Position above gear grid

---@class ui.components.inventory.ReadOnlyThreeByThreeGear.GearSlotElement.Opts
---@field box ui.components.Box
---@field gear_slot GearSlot
---@field parent_component ui.components.inventory.ReadOnlyThreeByThreeGear

---@class ui.components.inventory.ReadOnlyThreeByThreeGear.GearSlotElement : Element
---@field new fun(opts: ui.components.inventory.ReadOnlyThreeByThreeGear.GearSlotElement.Opts): ui.components.inventory.ReadOnlyThreeByThreeGear.GearSlotElement
---@field init fun(self: ui.components.inventory.ReadOnlyThreeByThreeGear.GearSlotElement, opts: ui.components.inventory.ReadOnlyThreeByThreeGear.GearSlotElement.Opts)
---@field gear_slot GearSlot
---@field parent_component ui.components.inventory.ReadOnlyThreeByThreeGear
local GearSlotElement = class(
  "ui.components.inventory.ReadOnlyThreeByThreeGear.GearSlotElement",
  { super = Element }
)

function GearSlotElement:init(opts)
  validate(opts, {
    box = Box,
    gear_slot = GearSlot,
    parent_component = "table",
  })

  Element.init(self, opts.box, {
    z = Z.GEAR_DISPLAY + 1,
    interactable = true,
  })
  -- self:set_debug(true)

  self.gear_slot = opts.gear_slot
  self.parent_component = opts.parent_component
end

function GearSlotElement:_update()
  if self.targets.entered == 1 then
    self.parent_component:set_hovered_gear_slot(self.gear_slot)
  end
end

function GearSlotElement:_render() end

function ReadOnlyThreeByThreeGear:init(opts)
  validate(opts, {})

  local w = RECTANGLE * 3 + GAP * 2
  local h = RECTANGLE * 3 + GAP * 2

  local box = Box.new(Position.new(TOP_LEFT, TOP_RIGHT), w, h)

  Element.init(self, box, {
    z = Z.GEAR_DISPLAY,
  })

  self.texture =
    assert(Asset.sprites.gear_display, "Gear display texture not found")

  self.hovered_gear_slot = nil

  -- Create individual hoverable elements for each gear slot
  self.gear_slot_elements = {}
  self:_create_gear_slot_elements()

  -- Create persistent tooltip
  self:_create_tooltip()
end

--- Create hoverable elements for each gear slot
function ReadOnlyThreeByThreeGear:_create_gear_slot_elements()
  local slots = {
    { GearSlot.TOOL_LEFT, 0, 0 },
    { GearSlot.HAT, 0, 1 },
    { GearSlot.TOOL_RIGHT, 0, 2 },
    { GearSlot.RING_LEFT, 1, 0 },
    { GearSlot.NECKLACE, 1, 1 },
    { GearSlot.RING_RIGHT, 1, 2 },
    { GearSlot.SHIRT, 2, 0 },
    { GearSlot.PANTS, 2, 1 },
    { GearSlot.SHOES, 2, 2 },
  }

  for _, slot_info in ipairs(slots) do
    local gear_slot, row, col = slot_info[1], slot_info[2], slot_info[3]
    -- Position RELATIVE to parent (which is at TOP_LEFT, TOP_RIGHT)
    local slot_box = Box.new(
      Position.new(col * X_OFFSET, row * Y_OFFSET),
      RECTANGLE,
      RECTANGLE
    )
    local slot_element = GearSlotElement.new {
      box = slot_box,
      gear_slot = gear_slot,
      parent_component = self,
    }
    self:append_child(slot_element)
    table.insert(self.gear_slot_elements, slot_element)
  end
end

--- Create the persistent tooltip element
function ReadOnlyThreeByThreeGear:_create_tooltip()
  -- Create text element with a function that dynamically builds content
  self.tooltip_description = Text.new {
    function()
      if not self.hovered_gear_slot then
        return {}
      end

      local gear = State.gear_manager:get_gear(self.hovered_gear_slot)
      if not gear or not gear.description then
        return {}
      end

      local content = {}
      for _, desc_item in ipairs(gear.description) do
        if type(desc_item) == "string" then
          table.insert(content, {
            text = desc_item,
            color = Colors.white,
            font = Asset.fonts.typography.paragraph_lg,
          })
        else
          table.insert(content, desc_item)
        end
      end

      return content
    end,
    box = Box.new(Position.new(0, 0), TOOLTIP_WIDTH - 40, TOOLTIP_HEIGHT - 80),
    text_align = "left",
    vertical_align = "top",
  }

  ---@type layout.Flex
  local flex = {
    direction = "column",
    align_items = "start",
    justify_content = "start",
    gap = 0,
  }

  local title_function = function()
    if not self.hovered_gear_slot then
      return ""
    end

    local gear = State.gear_manager:get_gear(self.hovered_gear_slot)
    if not gear then
      return ""
    end

    return string.format("%s (%s)", gear.name, gear.rarity)
  end

  self.tooltip_box = TitleBox.new {
    title = title_function,
    box = Box.new(Position.new(0, 0), TOOLTIP_WIDTH, TOOLTIP_HEIGHT),
    kind = "filled",
    z = Z.TOOLTIP,
    els = { self.tooltip_description },
    flex = flex,
  }
end

--- Set the currently hovered gear slot
---@param gear_slot GearSlot
function ReadOnlyThreeByThreeGear:set_hovered_gear_slot(gear_slot)
  self.hovered_gear_slot = gear_slot
end

--- Clear the hovered gear
function ReadOnlyThreeByThreeGear:clear_hovered_gear()
  self.hovered_gear_slot = nil
end

--- Update tooltip visibility based on hovered gear
function ReadOnlyThreeByThreeGear:_update(dt)
  if self.targets.entered == 1 and self.hovered_gear_slot then
    local gear = State.gear_manager:get_gear(self.hovered_gear_slot)
    if gear then
      -- Show tooltip at absolute position
      -- Content is updated dynamically via functions in the Text/TitleBox elements
      UI.root:show_absolute_tooltip(self.tooltip_box, TOOLTIP_X, TOOLTIP_Y)
    else
      -- No gear in slot, hide tooltip
      UI.root:hide_absolute_tooltip()
    end
  else
    -- Not hovering, hide tooltip
    UI.root:hide_absolute_tooltip()
  end
end

function ReadOnlyThreeByThreeGear:_render()
  local manager = State.gear_manager
  local tool_left = manager:get_gear(GearSlot.TOOL_LEFT)
  local hat = manager:get_gear(GearSlot.HAT)
  local tool_right = manager:get_gear(GearSlot.TOOL_RIGHT)
  local ring_left = manager:get_gear(GearSlot.RING_LEFT)
  local necklace = manager:get_gear(GearSlot.NECKLACE)
  local ring_right = manager:get_gear(GearSlot.RING_RIGHT)
  local shirt = manager:get_gear(GearSlot.SHIRT)
  local pants = manager:get_gear(GearSlot.PANTS)
  local shoes = manager:get_gear(GearSlot.SHOES)

  local x, y = self:get_geo()
  love.graphics.push "all"
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(self.texture, x, y, 0, 2, 2)

  -- Row 1: tool_left, hat, tool_right
  local draw_gear = function(gear, row, col)
    if not gear then
      return
    end

    local w = RECTANGLE
    local h = RECTANGLE

    local scale_w = w / gear.texture:getWidth()
    local scale_h = h / gear.texture:getHeight()
    local scale = math.min(scale_w, scale_h)

    love.graphics.draw(
      gear.texture,
      TOP_LEFT + col * X_OFFSET + (w - gear.texture:getWidth() * scale) / 2,
      TOP_RIGHT + row * Y_OFFSET + (h - gear.texture:getHeight() * scale) / 2,
      0,
      scale,
      scale
    )
  end

  draw_gear(tool_left, 0, 0)
  draw_gear(hat, 0, 1)
  draw_gear(tool_right, 0, 2)
  draw_gear(ring_left, 1, 0)
  draw_gear(necklace, 1, 1)
  draw_gear(ring_right, 1, 2)
  draw_gear(shirt, 2, 0)
  draw_gear(pants, 2, 1)
  draw_gear(shoes, 2, 2)

  love.graphics.pop()
end

function ReadOnlyThreeByThreeGear:_click() end

return ReadOnlyThreeByThreeGear
