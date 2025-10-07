local CardFactory = require "vibes.factory.card-factory"
local Container = require "ui.components.container"
local Text = require "ui.components.text"

---@class (exact) vibes.MonteCarloMode : vibes.BaseMode
---@field ui Element
---@field simulation_params vibes.MonteCarloParams
---@field simulation_results vibes.MonteCarloResults?
---@field is_running boolean
---@field current_simulation number
---@field total_simulations number
---@field results_text Element
local MonteCarloMode = {}

---@class (exact) vibes.MonteCarloParams
---@field tower_attack_speed number Base attack speed multiplier (0.5 to 3.0)
---@field tower_attack_range number Base attack range multiplier (0.5 to 3.0)
---@field tower_attack_damage number Base attack damage multiplier (0.5 to 3.0)
---@field tower_crit_chance number Base crit chance (0.0 to 0.5)
---@field enemy_health_multiplier number Enemy health multiplier (0.5 to 5.0)
---@field gold_reward_multiplier number Gold reward multiplier (0.5 to 3.0)
---@field card_rarity_common number Common card weight (0.0 to 1.0)
---@field card_rarity_uncommon number Uncommon card weight (0.0 to 1.0)
---@field card_rarity_rare number Rare card weight (0.0 to 1.0)
---@field card_rarity_epic number Epic card weight (0.0 to 1.0)
---@field card_rarity_legendary number Legendary card weight (0.0 to 1.0)
---@field simulation_count number Number of simulations to run (100 to 10000)
---@field waves_per_simulation number Number of waves per simulation (5 to 50)

---@class (exact) vibes.MonteCarloResults
---@field difficulty_scores number[] Array of difficulty scores from simulations
---@field average_difficulty number Average difficulty across all simulations
---@field min_difficulty number Minimum difficulty score
---@field max_difficulty number Maximum difficulty score
---@field win_rate number Percentage of simulations that were won
---@field average_waves_survived number Average number of waves survived

---@class (exact) vibes.SimulationState
---@field gold number Current gold
---@field towers vibes.Tower[] Current towers
---@field wave number Current wave number
---@field enemy_count number Enemies remaining in current wave
---@field player_health number Player health (0-100)

function MonteCarloMode:enter()
  self.ui = Container.new { box = Box.fullscreen() }
  UI.root:append_child(self.ui)

  self.is_running = false
  self.current_simulation = 0
  self.total_simulations = 0

  -- Initialize default simulation parameters
  self.simulation_params = {
    tower_attack_speed = 1.0,
    tower_attack_range = 1.0,
    tower_attack_damage = 1.0,
    tower_crit_chance = 0.05,
    enemy_health_multiplier = 1.0,
    gold_reward_multiplier = 1.0,
    card_rarity_common = 0.6,
    card_rarity_uncommon = 0.25,
    card_rarity_rare = 0.10,
    card_rarity_epic = 0.04,
    card_rarity_legendary = 0.01,
    simulation_count = 1000,
    waves_per_simulation = 20,
  }

  self:create_ui()
end

function MonteCarloMode:exit() UI.root:remove_child(self.ui) end

function MonteCarloMode:create_ui()
  local y_offset = 50
  local slider_width = 300
  local slider_height = 30
  local spacing = 40

  -- Title
  local title = Text.new {
    text = "Monte Carlo Tower Defense Simulation",
    box = Box.from(50, 20, 800, 30),
    font = Asset.fonts.typography.h1,
    color = Colors.white,
  }
  self.ui:append_child(title)

  -- Tower Parameters
  self:add_section_header("Tower Parameters", y_offset)
  y_offset = y_offset + spacing

  self:add_parameter_slider(
    "Attack Speed Multiplier",
    "tower_attack_speed",
    0.5,
    3.0,
    y_offset
  )
  y_offset = y_offset + spacing

  self:add_parameter_slider(
    "Attack Range Multiplier",
    "tower_attack_range",
    0.5,
    3.0,
    y_offset
  )
  y_offset = y_offset + spacing

  self:add_parameter_slider(
    "Attack Damage Multiplier",
    "tower_attack_damage",
    0.5,
    3.0,
    y_offset
  )
  y_offset = y_offset + spacing

  self:add_parameter_slider(
    "Crit Chance",
    "tower_crit_chance",
    0.0,
    0.5,
    y_offset
  )
  y_offset = y_offset + spacing + 20

  -- Enemy Parameters
  self:add_section_header("Enemy Parameters", y_offset)
  y_offset = y_offset + spacing

  self:add_parameter_slider(
    "Health Multiplier",
    "enemy_health_multiplier",
    0.5,
    5.0,
    y_offset
  )
  y_offset = y_offset + spacing + 20

  -- Economy Parameters
  self:add_section_header("Economy Parameters", y_offset)
  y_offset = y_offset + spacing

  self:add_parameter_slider(
    "Gold Reward Multiplier",
    "gold_reward_multiplier",
    0.5,
    3.0,
    y_offset
  )
  y_offset = y_offset + spacing + 20

  -- Card Rarity Parameters
  self:add_section_header("Card Rarity Weights", y_offset)
  y_offset = y_offset + spacing

  self:add_parameter_slider(
    "Common Weight",
    "card_rarity_common",
    0.0,
    1.0,
    y_offset
  )
  y_offset = y_offset + spacing

  self:add_parameter_slider(
    "Uncommon Weight",
    "card_rarity_uncommon",
    0.0,
    1.0,
    y_offset
  )
  y_offset = y_offset + spacing

  self:add_parameter_slider(
    "Rare Weight",
    "card_rarity_rare",
    0.0,
    1.0,
    y_offset
  )
  y_offset = y_offset + spacing

  self:add_parameter_slider(
    "Epic Weight",
    "card_rarity_epic",
    0.0,
    1.0,
    y_offset
  )
  y_offset = y_offset + spacing

  self:add_parameter_slider(
    "Legendary Weight",
    "card_rarity_legendary",
    0.0,
    1.0,
    y_offset
  )
  y_offset = y_offset + spacing + 20

  -- Simulation Parameters
  self:add_section_header("Simulation Parameters", y_offset)
  y_offset = y_offset + spacing

  self:add_parameter_slider(
    "Simulation Count",
    "simulation_count",
    100,
    10000,
    y_offset,
    true
  )
  y_offset = y_offset + spacing

  self:add_parameter_slider(
    "Waves Per Simulation",
    "waves_per_simulation",
    5,
    50,
    y_offset,
    true
  )
  y_offset = y_offset + spacing + 40

  -- Run Simulation Button
  local run_button = Button.new {
    on_click = function() self:start_simulation() end,
    draw = "Run Simulation",
    box = Box.from(50, y_offset, 200, 40),
    interactable = true,
  }
  self.ui:append_child(run_button)

  -- Results display area
  y_offset = y_offset + 60
  self.results_text = Text.new {
    text = "No simulation results yet.",
    box = Box.from(50, y_offset, 800, 300),
    font = Asset.fonts.default_16,
    color = Colors.white,
  }
  self.ui:append_child(self.results_text)
end

---@param title string
---@param y number
function MonteCarloMode:add_section_header(title, y)
  local header = Text.new {
    text = title,
    box = Box.from(50, y, 400, 25),
    font = Asset.fonts.typography.h2,
    color = Colors.yellow,
  }
  self.ui:append_child(header)
end

---@param label string
---@param param_name string
---@param min_val number
---@param max_val number
---@param y number
---@param is_integer? boolean
function MonteCarloMode:add_parameter_slider(
  label,
  param_name,
  min_val,
  max_val,
  y,
  is_integer
)
  local label_text = Text.new {
    text = label,
    box = Box.from(50, y, 180, 30),
    font = Asset.fonts.default_16,
    color = Colors.white,
  }
  self.ui:append_child(label_text)

  -- Decrease button
  local decrease_btn = Button.new {
    text = "-",
    box = Box.from(240, y, 30, 30),
    on_click = function()
      local current = self.simulation_params[param_name]
      local step = is_integer and 1 or 0.1
      local new_value = math.max(min_val, current - step)
      if is_integer then
        new_value = math.floor(new_value + 0.5)
      end
      self.simulation_params[param_name] = new_value
      self:update_value_display(param_name, y)
    end,
  }
  self.ui:append_child(decrease_btn)

  -- Increase button
  local increase_btn = Button.new {
    text = "+",
    box = Box.from(320, y, 30, 30),
    on_click = function()
      local current = self.simulation_params[param_name]
      local step = is_integer and 1 or 0.1
      local new_value = math.min(max_val, current + step)
      if is_integer then
        new_value = math.floor(new_value + 0.5)
      end
      self.simulation_params[param_name] = new_value
      self:update_value_display(param_name, y)
    end,
  }
  self.ui:append_child(increase_btn)

  -- Value display
  self:update_value_display(param_name, y)
end

---@param param_name string
---@param y number
function MonteCarloMode:update_value_display(param_name, y)
  local value = self.simulation_params[param_name]
  local value_text = string.format("%.3f", value)
  if value == math.floor(value) then
    value_text = string.format("%d", value)
  end

  local value_display = Text.new {
    text = value_text,
    box = Box.from(360, y, 80, 30),
    font = Asset.fonts.default_16,
    color = Colors.green,
  }
  -- Note: In a real implementation, we'd want to update existing text rather than create new
  self.ui:append_child(value_display)
end

function MonteCarloMode:start_simulation()
  if self.is_running then
    return
  end

  self.is_running = true
  self.current_simulation = 0
  self.total_simulations = self.simulation_params.simulation_count
  self.simulation_results = {
    difficulty_scores = {},
    average_difficulty = 0,
    min_difficulty = math.huge,
    max_difficulty = -math.huge,
    win_rate = 0,
    average_waves_survived = 0,
  }

  logger.info(
    "Starting Monte Carlo simulation with %d runs",
    self.total_simulations
  )
end

function MonteCarloMode:update(dt)
  if not self.is_running then
    return
  end

  -- Run one simulation per frame to avoid blocking
  if self.current_simulation < self.total_simulations then
    self.current_simulation = self.current_simulation + 1
    local result = self:run_single_simulation()

    table.insert(
      self.simulation_results.difficulty_scores,
      result.difficulty_score
    )
    self.simulation_results.min_difficulty =
      math.min(self.simulation_results.min_difficulty, result.difficulty_score)
    self.simulation_results.max_difficulty =
      math.max(self.simulation_results.max_difficulty, result.difficulty_score)
    self.simulation_results.average_waves_survived = self.simulation_results.average_waves_survived
      + result.waves_survived

    if result.won then
      self.simulation_results.win_rate = self.simulation_results.win_rate + 1
    end

    -- Update progress
    if
      self.current_simulation % 100 == 0
      or self.current_simulation == self.total_simulations
    then
      logger.info(
        "Simulation progress: %d/%d",
        self.current_simulation,
        self.total_simulations
      )
    end
  else
    -- Finish simulation
    self:finish_simulation()
  end
end

---@return { difficulty_score: number, waves_survived: number, won: boolean }
function MonteCarloMode:run_single_simulation()
  -- Create simulation state
  local sim_state = {
    gold = 100, -- Starting gold
    towers = {},
    wave = 1,
    player_health = 100,
  }

  local waves_survived = 0
  local total_difficulty = 0

  -- Run waves
  for wave_num = 1, self.simulation_params.waves_per_simulation do
    local wave_result = self:simulate_wave(sim_state, wave_num)

    if wave_result.player_died then
      break
    end

    waves_survived = waves_survived + 1
    total_difficulty = total_difficulty + wave_result.difficulty_contribution

    -- Buy cards with earned gold
    sim_state.gold = sim_state.gold + wave_result.gold_earned
    self:simulate_card_purchases(sim_state)
  end

  local difficulty_score = waves_survived > 0
      and (total_difficulty / waves_survived)
    or 0
  local won = waves_survived >= self.simulation_params.waves_per_simulation

  return {
    difficulty_score = difficulty_score,
    waves_survived = waves_survived,
    won = won,
  }
end

---@param sim_state vibes.SimulationState
---@param wave_num number
---@return { player_died: boolean, difficulty_contribution: number, gold_earned: number }
function MonteCarloMode:simulate_wave(sim_state, wave_num)
  -- Calculate wave difficulty based on wave number
  local base_enemy_health = 100 + (wave_num - 1) * 50
  local enemy_health = base_enemy_health
    * self.simulation_params.enemy_health_multiplier
  local enemy_count = math.min(10 + wave_num, 50) -- Cap at 50 enemies

  local total_enemy_health = enemy_health * enemy_count
  local total_tower_dps = self:calculate_total_tower_dps(sim_state.towers)

  -- Simple combat simulation: can towers kill all enemies before they reach the end?
  local time_to_kill_all = total_enemy_health / math.max(total_tower_dps, 1)
  local enemy_travel_time = 10 -- Assume 10 seconds to traverse the path

  local enemies_that_escape = 0
  if time_to_kill_all > enemy_travel_time then
    local enemies_killed =
      math.floor((total_tower_dps * enemy_travel_time) / enemy_health)
    enemies_that_escape = math.max(0, enemy_count - enemies_killed)
  end

  -- Each escaped enemy deals 10 damage
  local damage_taken = enemies_that_escape * 10
  sim_state.player_health = sim_state.player_health - damage_taken

  -- Calculate gold reward
  local enemies_killed = enemy_count - enemies_that_escape
  local base_gold_per_enemy = 10
  local gold_earned = enemies_killed
    * base_gold_per_enemy
    * self.simulation_params.gold_reward_multiplier

  -- Calculate difficulty contribution (higher when more enemies escape)
  local escape_rate = enemies_that_escape / enemy_count
  local difficulty_contribution = escape_rate * wave_num

  return {
    player_died = sim_state.player_health <= 0,
    difficulty_contribution = difficulty_contribution,
    gold_earned = gold_earned,
  }
end

---@param towers vibes.Tower[]
---@return number
function MonteCarloMode:calculate_total_tower_dps(towers)
  local total_dps = 0

  for _, tower in ipairs(towers) do
    local damage = tower:get_damage()
      * self.simulation_params.tower_attack_damage
    local attack_speed = tower:get_attack_speed()
      * self.simulation_params.tower_attack_speed
    local crit_multiplier = 1 + (self.simulation_params.tower_crit_chance * 0.5) -- Assume 50% crit damage

    local dps = damage * attack_speed * crit_multiplier
    total_dps = total_dps + dps
  end

  return total_dps
end

---@param sim_state vibes.SimulationState
function MonteCarloMode:simulate_card_purchases(sim_state)
  -- Simple card purchase simulation: buy cards if we have enough gold
  local card_cost = 150 -- Average card cost

  while sim_state.gold >= card_cost do
    sim_state.gold = sim_state.gold - card_cost

    -- Generate a random card based on our rarity weights
    local card = self:generate_weighted_card()

    -- If it's a tower card, add the tower to our simulation
    if card.kind == CardKind.TOWER and card.tower then
      table.insert(sim_state.towers, card.tower)
    end
    -- Enhancement cards would modify existing towers, but we'll skip that for simplicity
  end
end

---@class (exact) vibes.MockCard
---@field kind CardKind
---@field rarity Rarity
---@field tower vibes.Tower?
---@field name string

---@return vibes.MockCard
function MonteCarloMode:generate_weighted_card()
  -- Normalize rarity weights
  local total_weight = self.simulation_params.card_rarity_common
    + self.simulation_params.card_rarity_uncommon
    + self.simulation_params.card_rarity_rare
    + self.simulation_params.card_rarity_epic
    + self.simulation_params.card_rarity_legendary

  if total_weight <= 0 then
    total_weight = 1
    self.simulation_params.card_rarity_common = 1
  end

  local roll = math.random() * total_weight
  local cumulative = 0

  local rarities = {
    {
      rarity = Rarity.COMMON,
      weight = self.simulation_params.card_rarity_common,
    },
    {
      rarity = Rarity.UNCOMMON,
      weight = self.simulation_params.card_rarity_uncommon,
    },
    { rarity = Rarity.RARE, weight = self.simulation_params.card_rarity_rare },
    { rarity = Rarity.EPIC, weight = self.simulation_params.card_rarity_epic },
    {
      rarity = Rarity.LEGENDARY,
      weight = self.simulation_params.card_rarity_legendary,
    },
  }

  for _, rarity_info in ipairs(rarities) do
    cumulative = cumulative + rarity_info.weight
    if roll <= cumulative then
      -- For simulation purposes, create a simple tower card
      return self:create_simulation_tower_card(rarity_info.rarity)
    end
  end

  return self:create_simulation_tower_card(Rarity.COMMON)
end

---@param rarity Rarity
---@return vibes.MockCard
function MonteCarloMode:create_simulation_tower_card(rarity)
  -- Create a basic tower for simulation
  local base_damage = 50
  local base_attack_speed = 1.0
  local base_range = 3.0

  -- Scale stats based on rarity
  local rarity_multipliers = {
    [Rarity.COMMON] = 1.0,
    [Rarity.UNCOMMON] = 1.2,
    [Rarity.RARE] = 1.5,
    [Rarity.EPIC] = 2.0,
    [Rarity.LEGENDARY] = 3.0,
  }

  local multiplier = rarity_multipliers[rarity] or 1.0

  local stats = require("vibes.data.tower-stats").new {
    damage = Stat.new(base_damage * multiplier, 1),
    attack_speed = Stat.new(base_attack_speed * multiplier, 1),
    range = Stat.new(base_range * multiplier, 1),
    enemy_targets = Stat.new(1, 1),
  }

  local tower =
    require("vibes.tower.base").new(stats, Asset.sprites.tower_archer, {
      kind = TowerKind.SHOOTER,
      element_kind = ElementKind.PHYSICAL,
    })

  -- Create a mock card
  ---@type vibes.MockCard
  local card = {
    kind = CardKind.TOWER,
    rarity = rarity,
    tower = tower,
    name = "Simulation Tower (" .. rarity .. ")",
  }

  return card
end

function MonteCarloMode:finish_simulation()
  self.is_running = false

  -- Calculate final statistics
  local total_difficulty = 0
  for _, score in ipairs(self.simulation_results.difficulty_scores) do
    total_difficulty = total_difficulty + score
  end

  self.simulation_results.average_difficulty = total_difficulty
    / self.total_simulations
  self.simulation_results.win_rate = (
    self.simulation_results.win_rate / self.total_simulations
  ) * 100
  self.simulation_results.average_waves_survived = self.simulation_results.average_waves_survived
    / self.total_simulations

  -- Update results display
  local results_text = string.format(
    [[
MONTE CARLO SIMULATION RESULTS
==============================

Simulations Run: %d
Average Difficulty Score: %.2f
Min Difficulty: %.2f
Max Difficulty: %.2f
Win Rate: %.1f%%
Average Waves Survived: %.1f

DIFFICULTY ANALYSIS:
- Scores closer to 0 indicate easier gameplay
- Higher scores indicate more challenging gameplay
- Win rate shows percentage of full completions

PARAMETER SUMMARY:
Tower Attack Speed: %.2fx
Tower Attack Range: %.2fx  
Tower Attack Damage: %.2fx
Tower Crit Chance: %.1f%%
Enemy Health: %.2fx
Gold Rewards: %.2fx
]],
    self.total_simulations,
    self.simulation_results.average_difficulty,
    self.simulation_results.min_difficulty,
    self.simulation_results.max_difficulty,
    self.simulation_results.win_rate,
    self.simulation_results.average_waves_survived,
    self.simulation_params.tower_attack_speed,
    self.simulation_params.tower_attack_range,
    self.simulation_params.tower_attack_damage,
    self.simulation_params.tower_crit_chance * 100,
    self.simulation_params.enemy_health_multiplier,
    self.simulation_params.gold_reward_multiplier
  )

  -- Update results display by replacing the text component
  UI.root:remove_child(self.results_text)
  self.results_text = Text.new {
    text = results_text,
    box = Box.from(50, 650, 800, 300),
    font = Asset.fonts.default_16,
    color = Colors.white,
  }
  self.ui:append_child(self.results_text)

  logger.info "Monte Carlo simulation completed!"
  logger.info(
    "Average difficulty: %.2f",
    self.simulation_results.average_difficulty
  )
  logger.info("Win rate: %.1f%%", self.simulation_results.win_rate)
end

function MonteCarloMode:draw()
  -- Draw background
  love.graphics.setColor(0.1, 0.1, 0.2, 1)
  love.graphics.rectangle(
    "fill",
    0,
    0,
    Config.window_size.width,
    Config.window_size.height
  )

  -- Draw progress bar if simulation is running
  if self.is_running then
    local progress = self.current_simulation / self.total_simulations
    local bar_width = 400
    local bar_height = 20
    local bar_x = (Config.window_size.width - bar_width) / 2
    local bar_y = Config.window_size.height - 100

    -- Background
    love.graphics.setColor(0.3, 0.3, 0.3, 1)
    love.graphics.rectangle("fill", bar_x, bar_y, bar_width, bar_height)

    -- Progress
    love.graphics.setColor(0.2, 0.8, 0.2, 1)
    love.graphics.rectangle(
      "fill",
      bar_x,
      bar_y,
      bar_width * progress,
      bar_height
    )

    -- Progress text
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(Asset.fonts.default_16)
    local progress_text = string.format(
      "Simulation Progress: %d/%d (%.1f%%)",
      self.current_simulation,
      self.total_simulations,
      progress * 100
    )
    love.graphics.print(progress_text, bar_x, bar_y - 25)
  end
end

function MonteCarloMode:keypressed(key)
  if key == "escape" then
    State.mode = ModeName.MAIN_MENU
    return true
  end
  return false
end

return require("vibes.base-mode").wrap(MonteCarloMode)
