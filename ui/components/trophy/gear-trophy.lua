local ButtonElement = require "ui.elements.button"
local GearItem = require "ui.components.pack.gear-item"
local Inventory = require "ui.components.inventory"
local ScaledImg = require "ui.components.scaled-img"
local rectangle = require "utils.rectangle"

local GearFactory = require "gear.factory"

---@class components.trophy.GearTrophyUI.Opts
---@field on_complete? fun(): nil

---@class (exact) components.trophy.GearTrophyUI : Element
---@field new fun(opts: components.trophy.GearTrophyUI.Opts): components.trophy.GearTrophyUI
---@field init fun(self: components.trophy.GearTrophyUI, opts: components.trophy.GearTrophyUI.Opts)
---@field trophy_gear gear.Gear
---@field gear_element components.GearItemElement | nil
---@field _skip_button elements.Button
---@field _confirm_button elements.Button
---@field _on_complete? fun(): nil
local GearTrophyUI =
  class("components.trophy.GearTrophyUI", { super = Element })

-- Specialized trophy confirm button that extends the new button system
local TrophyConfirmButton =
  class("ui.components.trophy.TrophyConfirmButton", { super = ButtonElement })

function TrophyConfirmButton:init(opts)
  ButtonElement.init(self, {
    box = opts.box,
    label = "",
    on_click = opts.on_click,
  })
end

function TrophyConfirmButton:_render()
  local x, y, width, height = self:get_geo()

  -- Draw background using parent render
  ButtonElement._render(self)

  -- Custom label
  local text = "Select Gear"
  love.graphics.setFont(Asset.fonts.insignia_24)
  rectangle.center_text_in_rectangle(text, x, y, width, height, 1)
end

---@param opts components.trophy.GearTrophyUI.Opts
function GearTrophyUI:init(opts)
  validate(opts, {
    on_complete = "function?",
  })

  Element.init(self, Box.fullscreen(), {
    name = "GearTrophyUI",
    z = Z.TROPHY_SELECTION_INVENTORY,
    interactable = false,
    opacity = 0,
  })

  local trophy_gear = GearFactory:generate_random_gear()
  if not trophy_gear then
    return opts.on_complete()
  end

  self.trophy_gear = trophy_gear

  self._on_complete = opts.on_complete
  self:_add_layout()
  self:set_opacity(1)
end

function GearTrophyUI:_add_layout()
  local _, _, w, h = self:get_geo()

  -- Add armory background
  local armory_bg = ScaledImg.new {
    box = Box.new(Position.new(0, 0), w, h),
    texture = Asset.sprites.armory_background,
    scale_style = "stretch",
    z = Z.TROPHY_SELECTION_BACKGROUND,
  }
  self:append_child(armory_bg)

  -- Create inventory component in the center
  local inventory = Inventory.new {
    box = Box.new(Position.zero(), w, h),
    z = Z.TROPHY_SELECTION_INVENTORY,
  }
  self:append_child(inventory)

  local gear_x = 275
  local gear_y = 555
  local gear_size = 150

  -- Create trophy gear element (now on the left)
  self.gear_element = GearItem.new {
    box = Box.new(Position.new(gear_x, gear_y), gear_size, gear_size),
    gear = self.trophy_gear,
    z = Z.TROPHY_SELECTION_CARDS,
    on_gear_added = function(gear) self:_confirm_selection() end,
  }
  self.gear_element._inventory = inventory
  self:append_child(self.gear_element)

  -- Create buttons
  local confirm_button_x = gear_x
  local confirm_button_y = gear_y + gear_size + 10
  self._confirm_button = TrophyConfirmButton.new {
    box = Box.new(Position.new(confirm_button_x, confirm_button_y), 200, 60),
    on_click = function(_) self:_confirm_selection() end,
  }

  local skip_button_x = confirm_button_x
  local skip_button_y = confirm_button_y + 60 + 10
  self._skip_button = ButtonElement.new {
    box = Box.new(Position.new(skip_button_x, skip_button_y), 200, 60),
    label = "Skip Selection",
    on_click = function() self:_skip_selection() end,
  }

  self:append_child(self._confirm_button)
  self:append_child(self._skip_button)
end

--- Confirm the trophy selection
function GearTrophyUI:_confirm_selection()
  local gear = self.trophy_gear
  if State.gear_manager:has_gear(gear) then
    self:_complete_trophy_selection()
    return
  end

  local inventory_slots = {
    GearSlot.INVENTORY_ONE,
    GearSlot.INVENTORY_TWO,
    GearSlot.INVENTORY_THREE,
    GearSlot.INVENTORY_FOUR,
  }

  local assigned = false
  for _, slot in ipairs(inventory_slots) do
    if not State.gear_manager:get_gear(slot) then
      State.gear_manager:assign_gear_to_slot(gear, slot)
      assigned = true
      logger.info(
        "Trophy gear selected and assigned to %s: %s",
        slot,
        gear.name
      )
      break
    end
  end

  if not assigned then
    logger.warn(
      "No available inventory slots for gear: %s",
      gear and gear.name or "unknown"
    )
    UI:create_user_message "No available inventory slots for gear!"
    return
  end

  self:_complete_trophy_selection()
end

--- Skip trophy selection
function GearTrophyUI:_skip_selection()
  logger.info "Trophy selection skipped"
  self:_complete_trophy_selection()
end

--- Complete the trophy selection
function GearTrophyUI:_complete_trophy_selection()
  if self._on_complete then
    self._on_complete()
  end
end

function GearTrophyUI:_render() end
function GearTrophyUI:_update() end
function GearTrophyUI:__tostring() return "GearTrophyUI" end

return GearTrophyUI
