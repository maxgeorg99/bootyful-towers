---@diagnostic disable

--- Deterministic testing framework for consistent game simulations
--- Controls all randomness sources to ensure reproducible test results
---@class vibes.testing.DeterministicFramework
local DeterministicFramework = {}

local Random = require "vibes.engine.random"

--- Stores original random instances for restoration
---@type table<string, Random>
local original_randoms = {}

--- Whether the framework is currently active
local is_active = false

--- Current test seed
local current_seed = nil

--- List of all known random generators in the game that need to be controlled
local RANDOM_GENERATORS = {
  "TowerUpgradeOptions",
  "CriticalDamage",
  "general", -- from gear/factory.lua and card factory
  "helmet",
  "armor",
  "weapon",
  "accessory",
}

--- Initialize the deterministic framework with a specific seed
---@param seed number The seed to use for all random number generation
function DeterministicFramework.initialize(seed)
  if is_active then
    DeterministicFramework.cleanup()
  end

  current_seed = seed
  is_active = true

  -- Override Config.seed to ensure all new Random instances use our test seed
  Config.seed = seed

  -- Store original randoms and replace them with seeded versions
  local gear_factory = require "gear.factory"
  if gear_factory.random then
    for name, random_instance in pairs(gear_factory.random) do
      original_randoms[name] = random_instance
      gear_factory.random[name] = Random.new { name = name }
    end
  end

  -- Reset any existing Random instances that might be cached in modules
  -- This forces them to reinitialize with the new seed
  package.loaded["vibes.data.gamestate"] = nil
  package.loaded["vibes.data.critical-damage"] = nil
  package.loaded["vibes.factory.card-factory"] = nil

  logger.info("DeterministicFramework: Initialized with seed %d", seed)
end

--- Cleanup the deterministic framework and restore original random generators
function DeterministicFramework.cleanup()
  if not is_active then
    return
  end

  -- Restore original randoms
  local gear_factory = require "gear.factory"
  if gear_factory.random then
    for name, original_random in pairs(original_randoms) do
      gear_factory.random[name] = original_random
    end
  end

  original_randoms = {}
  is_active = false
  current_seed = nil

  logger.info "DeterministicFramework: Cleaned up"
end

--- Get the current test seed
---@return number?
function DeterministicFramework.get_current_seed() return current_seed end

--- Check if the framework is currently active
---@return boolean
function DeterministicFramework.is_active() return is_active end

--- Create a deterministic game state for testing
---@param opts? { seed?: number, level?: number, character?: CharacterKind }
---@return vibes.GameState
function DeterministicFramework.create_test_state(opts)
  opts = opts or {}
  local seed = opts.seed or 12345
  local level = opts.level or 1
  local character = opts.character or CharacterKind.BLACKSMITH

  DeterministicFramework.initialize(seed)

  -- Create a fresh game state
  local GameState = require "vibes.data.gamestate"
  local state = GameState.new()

  -- Set up deterministic starting conditions
  state.selected_character = character
  state.player.gold = 100 -- Standard starting gold for tests
  state.player.health = Config.player.default_health
  state.player.energy = Config.player.default_energy

  -- Initialize with a specific level
  state.levels:set_current_level(level)

  return state
end

return DeterministicFramework
