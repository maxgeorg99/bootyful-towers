local Level = require "vibes.level"
local LevelInfinite = require "vibes.level.infinite"
local Random = require "vibes.engine.random"

local random = Random.new { name = "level-manager" }

local available_levels = {
  -- Main progression levels (known to work)
  "assets/level-json/1_level_1.json",
  "assets/level-json/2_level_2.json",
  "assets/level-json/3_level_3.json",
  "assets/level-json/4_level_4.json",
  "assets/level-json/5_level_5.json",
  "assets/level-json/6_level_6.json",
  "assets/level-json/7_level_7.json",
  "assets/level-json/8_level_8.json",
  "assets/level-json/9_level_9.json",
  "assets/level-json/10_level_10.json",

  -- Additional level variations (tested and working)
  -- "assets/level-json/2_morals.json",
  -- "assets/level-json/3_nonono.json",
  -- "assets/level-json/4_boxes.json",
  -- "assets/level-json/5_leaked.json",
  -- "assets/level-json/6_king_time.json",
}

---@class (exact) vibes.LevelManager.Opts
---@field starting_level number
---@field available_levels string[]?
---@field test_wave number?
---@field test_level number?

---@class vibes.LevelManager : vibes.Class
---@field new fun(opts: vibes.LevelManager.Opts): vibes.LevelManager
---@field init fun(self: self, opts: vibes.LevelManager.Opts)
---@field levels vibes.Level[]
---@field starting_level number
---@field current_level_idx number
---@field current_wave number
local LevelManager = class "vibes.LevelManager"

---@param opts vibes.LevelManager.Opts
function LevelManager:init(opts)
  -- Use provided levels or fall back to default available_levels
  local levels_to_use = opts.available_levels or available_levels
  -- Build levels in the exact order provided in levels_to_use.
  -- This preserves the sequence defined in available_levels (or any provided list)
  -- rather than grouping by JSON level index or randomizing among duplicates.
  local levels = {}
  for _, path_to_level_json in ipairs(levels_to_use) do
    table.insert(levels, Level.new { level_data_path = path_to_level_json })
  end

  -- Begin: Add infinite levels only when using default available levels
  -- If specific levels were provided (via --levels), do NOT append infinite levels
  if opts.available_levels == nil then
    -- Only create infinite levels for levels that don't already exist
    for i = #levels + 1, 30 do
      if levels[i] == nil then
        local path_to_level_json = random:of_list(levels_to_use)
        local level = LevelInfinite.new {
          level_data_path = path_to_level_json,
          level = i,
        }
        table.insert(levels, level)
      end
    end
  end

  -- validate starting level
  self.levels = levels
  if opts.starting_level > #self.levels then
    self.starting_level = #self.levels
  end

  if opts.starting_level < 1 then
    self.starting_level = 1
  end

  self.starting_level = opts.starting_level
  self.current_level_idx = self.starting_level
  self.current_wave = 1

  -- Handle test wave/level parameters for direct wave testing
  if opts.test_level then
    self.current_level_idx =
      math.max(1, math.min(opts.test_level, #self.levels))
    logger.info("LevelManager: Testing level %d", self.current_level_idx)
  end

  if opts.test_wave then
    -- Get the target level to validate wave number
    local target_level = self.levels[self.current_level_idx]
    local max_waves = target_level
        and target_level.waves
        and #target_level.waves
      or 1
    self.current_wave = math.max(1, math.min(opts.test_wave, max_waves))
    logger.info(
      "LevelManager: Testing wave %d of %d in level %d",
      self.current_wave,
      max_waves,
      self.current_level_idx
    )
  end

  validate(self, {
    levels = List { Level },
  })
end

function LevelManager:reset_wave_state()
  logger.info(
    "ready_next_wave: %d, %d",
    self.current_level_idx,
    self.current_wave
  )

  State.enemies = {}
  State.projectiles = {}

  -- Clear poison pools when starting a new wave
  PoisonPoolSystem.poison_pools = {}

  -- Clear fire pools when starting a new wave
  FirePoolSystem.fire_pools = {}

  SoundManager:play_game_start()

  ---@type vibes.effect.BeforePlayingActionsState

  -- Flat energy system: Award 2 energy between rounds, with base of 4 for new games
  local energy_to_award = 2
  local result = { energy = energy_to_award }

  State.gear_manager:for_gear_in_active_gear(function(gear)
    -- Gear manages it's own state
    gear.hooks.before_playing_actions(gear, result)
  end)

  -- Add the awarded energy to current energy (allowing accumulation) but cap at max_energy
  State.player.energy = math.min(
    State.player.energy + math.max(result.energy, 0),
    Config.player.max_energy
  )
  State.spawner:reset()
end

function LevelManager:reset_game_state()
  self.current_level_idx = self.starting_level
  self.current_wave = 1

  State.towers = {}
  State.enemies = {}
  State.projectiles = {}
  State.deck:reset()
end

function LevelManager:reset_level_state()
  self.current_wave = 1

  ---@type hooks.BeforeLevelStart.Result
  local result = {
    discards = Config.player.default_discards,
    energy = Config:get_starting_energy_for_level(
      self:get_current_level_number()
    ),
    level = self:get_current_level(),
  }

  State:for_each_active_hook(
    function(item) return item.hooks.before_level_starts(item, result) end
  )

  -- Apply the energy and discards from the hooks result to the player
  State.player.energy = result.energy
  State.player.discards = result.discards

  -- Reset applied towers modifiers
  for _, tower in ipairs(State.towers or {}) do
    tower:reset_level_state()
  end

  State.towers = {}
  State.enemies = {}
  State.projectiles = {}

  -- Clear poison pools when starting a new level
  PoisonPoolSystem.poison_pools = {}

  -- Clear fire pools when starting a new level
  FirePoolSystem.fire_pools = {}

  -- Only reset UI if GAME and ui exist (they might not during initialization)
  if GAME and GAME.ui then
    GAME.ui:reset()
  end

  -- Make sure color swap shader is initialized with current level
  local asset = require "vibes.asset"
  local column = math.min((self.current_level_idx - 1) % 5, 4)
  asset.shaders.color_swap:send { levelColumn = column }

  self:reset_wave_state()
end

--- @returns boolean
function LevelManager:advance_to_next_level()
  if self.current_level_idx + 1 > #self.levels then
    return false
  end

  self:set_current_level(self.current_level_idx + 1)

  -- Update the color_swap shader level column based on current level
  local asset = require "vibes.asset"
  local column = math.min((self.current_level_idx - 1) % 5, 4)
  asset.shaders.color_swap:send { levelColumn = column }

  for _, tower in ipairs(State.towers) do
    tower:reset_level_state()
  end

  return true
end

function LevelManager:complete_wave()
  local level = self:get_current_level()
  local max_waves = level.waves and #level.waves or 0

  logger.info(
    "complete_wave: current_wave=%d, max_waves=%d, level_name=%s",
    self.current_wave,
    max_waves,
    level.name or "unknown"
  )

  local params = { wave = self:get_current_wave() }
  State:for_each_active_hook(
    function(item) item.hooks.after_wave_ends(item, params) end
  )

  self.current_wave = self.current_wave + 1

  -- Add safety check to prevent going beyond available waves
  if self.current_wave > max_waves then
    logger.warn(
      "complete_wave: current_wave (%d) exceeds max_waves (%d), level should be complete",
      self.current_wave,
      max_waves
    )
    -- Don't modify current_wave here - let the level completion logic handle it
  end

  self:reset_wave_state()
end

function LevelManager:level_complete()
  -- Always enforce 8 waves per level (3 regular + 5 bonus)
  return self.current_wave > 8
end

--- Check if we're currently in the main waves (waves 1-3)
---@return boolean
function LevelManager:is_in_main_waves() return self.current_wave <= 3 end

--- Check if we're currently in bonus waves (waves 4-8)
---@return boolean
function LevelManager:is_in_bonus_waves()
  return self.current_wave > 3 and self.current_wave <= 8
end

--- Check if we just completed the main waves (wave 3)
---@return boolean
function LevelManager:just_completed_main_waves()
  return self.current_wave == 4 -- We're now on wave 4, meaning we just completed wave 3
end

--- Check if we just completed a bonus wave (waves 4-8)
---@return boolean
function LevelManager:just_completed_bonus_wave()
  return self.current_wave > 4 and self.current_wave <= 9 -- We completed waves 4-8
end

--- Get the current bonus wave number (1-5 for waves 4-8)
---@return number|nil
function LevelManager:get_current_bonus_wave_number()
  if self:is_in_bonus_waves() then
    return self.current_wave - 3
  end
  return nil
end

function LevelManager:get_current_level()
  return assert(
    self.levels[self.current_level_idx],
    "Must have a current level"
  )
end

--- Get the actual level number (from filename) rather than the array index
---@return number The actual level number extracted from the level name
function LevelManager:get_current_level_number()
  local level = self:get_current_level()

  -- Try to extract level number from the level name (e.g., "5_level_5" -> 5)
  if level.name then
    local level_num = level.name:match "^(%d+)_"
    if level_num then
      return tonumber(level_num)
    end
  end

  -- Fallback to level_idx from JSON data or array index
  return level.level_idx or self.current_level_idx
end

function LevelManager:get_current_wave()
  local level = self:get_current_level()
  local wave_count = level.waves and #level.waves or 0

  logger.info(
    "get_current_wave: current_wave=%d, level has %d waves, level_idx=%d, level_name=%s",
    self.current_wave,
    wave_count,
    self.current_level_idx,
    level.name or "unknown"
  )

  -- Check if current_wave is out of bounds
  if self.current_wave < 1 or self.current_wave > wave_count then
    logger.error(
      "Wave index out of bounds: current_wave=%d, available waves=1-%d",
      self.current_wave,
      wave_count
    )

    -- Reset to wave 1 as a safety measure
    self.current_wave = 1
    logger.info "Reset current_wave to 1 as safety measure"
  end

  return assert(
    level.waves[self.current_wave],
    string.format(
      "Must have a current wave: %d (level has %d waves, level='%s')",
      self.current_wave,
      wave_count,
      level.name or "unknown"
    )
  )
end

---@param level_idx number
function LevelManager:set_current_level(level_idx)
  if level_idx > #self.levels then
    error "Max level reached"
  end

  if level_idx < 1 then
    level_idx = self.starting_level
  end

  if #self.levels == 0 then
    error "No levels available"
  end

  self.current_level_idx = level_idx
  self:reset_level_state()
end

return LevelManager
