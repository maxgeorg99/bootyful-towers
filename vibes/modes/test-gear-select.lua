local GearFactory = require "gear.factory"
local GearSelection = require "ui.components.pack.gear-selection"

---@class vibes.TestGearSelectMode : vibes.BaseMode
---@field _overlay Element?
---@field _selected_gears gear.Gear[]
---@field _resolved boolean
local TestGearSelectMode = {}

local function remove_overlay(overlay)
  if overlay then
    UI.root:remove_child(overlay)
  end
end

local function add_unique(list, item)
  if not item then
    return
  end

  for _, existing in ipairs(list) do
    if existing == item then
      return
    end
  end

  table.insert(list, item)
end

function TestGearSelectMode:enter()
  self._resolved = false
  remove_overlay(self._overlay)

  -- Ensure we do not carry over a default deck when testing gear
  State.deck:reset()

  -- Apply tower level from command line argument if specified
  local tower_level = Config.tower_level
  if tower_level and tower_level > 1 then
    for _, card in ipairs(State.deck:get_all_cards()) do
      local tower_card = card:get_tower_card()
      if tower_card then
        tower_card:level_up_to(tower_level)
      end
    end
  end

  self:_prepare_selection()
end

function TestGearSelectMode:_prepare_selection()
  local available = GearFactory:get_all_available_gear()
  if #available == 0 then
    logger.warn "TestGearSelect: No available gear; skipping selection"
    State.mode = ModeName.GAME
    return
  end

  -- Reset gear manager to avoid prior test gear interfering
  State.gear_manager = require("gear.manager").new {}

  table.sort(
    available,
    function(a, b) return (a.name or "") < (b.name or "") end
  )

  local pack = {
    name = "Select Starting Gear",
    gear = available,
  }

  self._selected_gears = {}

  local overlay = GearSelection.new {
    pack = pack,
    items_per_page = 8,
    on_confirm = function(gear)
      logger.info(
        "TestGearSelect: Selected starting gear %s",
        gear and gear.name
      )
      add_unique(self._selected_gears, gear)
      self:_finalize_selection()
    end,
    on_cancel = function()
      logger.info "TestGearSelect: Selection cancelled"
      self:_finalize_selection()
    end,
    on_gear_added = function(gear)
      logger.info("TestGearSelect: Gear %s added via drag", gear and gear.name)
      add_unique(self._selected_gears, gear)
      self:_finalize_selection()
    end,
  }

  self._overlay = overlay
  UI.root:append_child(overlay)
end

function TestGearSelectMode:_finalize_selection()
  if self._resolved then
    return
  end
  self._resolved = true

  remove_overlay(self._overlay)
  self._overlay = nil

  -- Assign the selected gear to the gear manager slots in order
  local GearSlot = require "vibes.enum.gear-slot"

  local preferred_slots = {
    GearSlot.HAT,
    GearSlot.SHIRT,
    GearSlot.NECKLACE,
    GearSlot.RING_LEFT,
    GearSlot.RING_RIGHT,
    GearSlot.TOOL_LEFT,
    GearSlot.TOOL_RIGHT,
    GearSlot.PANTS,
    GearSlot.SHOES,
    GearSlot.INVENTORY_ONE,
    GearSlot.INVENTORY_TWO,
    GearSlot.INVENTORY_THREE,
    GearSlot.INVENTORY_FOUR,
  }

  local GearKind = require "vibes.enum.gear-kind"
  local kind_to_slot = {
    [GearKind.HAT] = GearSlot.HAT,
    [GearKind.SHIRT] = GearSlot.SHIRT,
    [GearKind.NECKLACE] = GearSlot.NECKLACE,
    [GearKind.PANTS] = GearSlot.PANTS,
    [GearKind.SHOES] = GearSlot.SHOES,
  }

  local manager = State.gear_manager

  for _, gear in ipairs(self._selected_gears or {}) do
    local function assign_gear()
      local preferred_slot = kind_to_slot[gear.kind]

      if preferred_slot ~= nil then
        local has_preferred = manager:get_gear(preferred_slot)

        -- Only enforce the preferred slot when it is empty and the gear kind matches.
        -- Otherwise fall back to inventory assignment to prevent validation errors.
        if not has_preferred and gear.kind ~= nil then
          local ok = pcall(
            function() manager:assign_gear_to_slot(gear, preferred_slot) end
          )

          if ok then
            return -- Successfully assigned to preferred slot
          else
            logger.warn(
              "TestGearSelect: preferred slot %s rejected gear %s",
              tostring(preferred_slot),
              tostring(gear.name)
            )
          end
        end
      end

      for _, fallback in ipairs(preferred_slots) do
        if not manager:get_gear(fallback) then
          local ok = pcall(
            function() manager:assign_gear_to_slot(gear, fallback) end
          )

          if ok then
            return -- Successfully assigned to fallback slot
          end
        end
      end

      logger.warn(
        "TestGearSelect: unable to assign gear %s; all slots rejected",
        tostring(gear.name)
      )
    end

    assign_gear()
  end

  self._selected_gears = nil

  State.mode = ModeName.GAME
end

function TestGearSelectMode:exit()
  remove_overlay(self._overlay)
  self._overlay = nil
  self._selected_gears = nil
  self._resolved = false
end

function TestGearSelectMode:update(_dt) end
function TestGearSelectMode:draw() end

return require("vibes.base-mode").wrap(TestGearSelectMode)
