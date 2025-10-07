--[[
GEAR FACTORY REQUIREMENTS:

CRITICAL CONSTRAINT: WE CAN NEVER HAVE TWO OF ANY GEAR!
- Gear is always just ONE instance of a gear for the entire game
- You cannot get copies of gear
- Each gear can only be acquired once per game session

This factory uses the global State.gear_manager to check what gear is already owned.
Unlike the card factory which generates new instances, this factory manages
unique gear instances and prevents duplicates by checking the gear manager.
Queen Madison was here
DO NOT CHANGE THE FORMAT OF gear/state.lua - it defines all availa:ble gear!
]]

local GearState = require "gear.state"
local Random = require "vibes.engine.random"

local random = {
  hat = Random.new { name = "gear-factory-hat" },
  necklace = Random.new { name = "gear-factory-necklace" },
  ring = Random.new { name = "gear-factory-ring" },
  tool = Random.new { name = "gear-factory-tool" },
  shirt = Random.new { name = "gear-factory-shirt" },
  pants = Random.new { name = "gear-factory-pants" },
  shoes = Random.new { name = "gear-factory-shoes" },
  general = Random.new { name = "gear-factory-general" },
}

---@class vibes.GearFactory
---@field new fun(): vibes.GearFactory
---@field init fun(self: vibes.GearFactory)
local GearFactory = class "vibes.GearFactory"

function GearFactory:init()
  -- No internal state needed - we use State.gear_manager to track ownership
end

--- Check if a specific gear is already owned by checking the gear manager
---@param gear gear.Gear
---@return boolean
function GearFactory:is_gear_owned(gear)
  return State.gear_manager:has_gear(gear)
end

--- Get all available gear of a specific kind that hasn't been acquired yet
---@param kind GearKind
---@return gear.Gear[]
function GearFactory:get_available_gear_by_kind(kind)
  local available = {}

  for gear_name, gear in pairs(GearState) do
    if gear.kind == kind and not self:is_gear_owned(gear) then
      table.insert(available, gear)
    end
  end

  return available
end

--- Get all gear that hasn't been acquired yet
---@return gear.Gear[]
function GearFactory:get_all_available_gear()
  local available = {}

  for gear_name, gear in pairs(GearState) do
    if not self:is_gear_owned(gear) then
      table.insert(available, gear)
    end
  end

  return available
end

--- Generate a random gear of a specific kind that hasn't been acquired
---@param kind GearKind
---@return gear.Gear?
function GearFactory:generate_random_gear_by_kind(kind)
  local available = self:get_available_gear_by_kind(kind)

  if #available == 0 then
    return nil -- No more gear of this kind available
  end

  local random_instance = random[string.lower(kind)] or random.general
  local index = random_instance:random(#available)
  local selected_gear = available[index]

  -- Note: The caller is responsible for adding the gear to State.gear_manager
  -- to prevent it from being offered again

  return selected_gear
end

--- Generate a random gear of any kind that hasn't been acquired
---@return gear.Gear?
function GearFactory:generate_random_gear()
  local available = self:get_all_available_gear()

  if #available == 0 then
    return nil -- No more gear available
  end

  local index = random.general:random(#available)
  local selected_gear = available[index]

  -- Note: The caller is responsible for adding the gear to State.gear_manager
  -- to prevent it from being offered again

  return selected_gear
end

--- Get count of available gear by kind
---@param kind GearKind
---@return number
function GearFactory:get_available_count_by_kind(kind)
  return #self:get_available_gear_by_kind(kind)
end

--- Get total count of available gear
---@return number
function GearFactory:get_total_available_count()
  return #self:get_all_available_gear()
end

return GearFactory.new()
