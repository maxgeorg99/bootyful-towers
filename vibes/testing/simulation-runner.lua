---@diagnostic disable

--- Command-line interface for running headless simulations
--- Integrates with the existing test runner for easy execution
---@class vibes.testing.SimulationRunner
local SimulationRunner = {}

local HeadlessSimulator = require "vibes.testing.headless-simulator"

--- Parse command line arguments for simulation configuration
---@param args string[] Command line arguments
---@return vibes.testing.SimulationConfig config
---@return number run_count
local function parse_simulation_args(args)
  local config = {
    seed = nil, -- Will use random if not specified
    max_rounds = 6,
    character = CharacterKind.BLACKSMITH,
    starting_level = 1,
    placement_strategy = "balanced",
    time_limit = 60,
    enable_logging = false,
  }

  local run_count = 1

  for i, arg in ipairs(args) do
    if arg == "--sim-seed" then
      local seed_arg = args[i + 1]
      if seed_arg and tonumber(seed_arg) then
        config.seed = tonumber(seed_arg)
      end
    elseif arg == "--sim-rounds" then
      local rounds_arg = args[i + 1]
      if rounds_arg and tonumber(rounds_arg) then
        config.max_rounds = tonumber(rounds_arg)
      end
    elseif arg == "--sim-runs" then
      local runs_arg = args[i + 1]
      if runs_arg and tonumber(runs_arg) then
        run_count = tonumber(runs_arg)
      end
    elseif arg == "--sim-character" then
      local char_arg = args[i + 1]
      if char_arg then
        -- Map string to CharacterKind enum
        if char_arg:upper() == "BLACKSMITH" then
          config.character = CharacterKind.BLACKSMITH
          -- Add other character types as they become available
        end
      end
    elseif arg == "--sim-strategy" then
      local strategy_arg = args[i + 1]
      if strategy_arg then
        config.placement_strategy = strategy_arg
      end
    elseif arg == "--sim-level" then
      local level_arg = args[i + 1]
      if level_arg and tonumber(level_arg) then
        config.starting_level = tonumber(level_arg)
      end
    elseif arg == "--sim-time-limit" then
      local time_arg = args[i + 1]
      if time_arg and tonumber(time_arg) then
        config.time_limit = tonumber(time_arg)
      end
    elseif arg == "--sim-verbose" then
      config.enable_logging = true
    elseif arg == "--sim-map" then
      config.generate_map_image = true
    elseif arg == "--sim-map-dir" then
      local dir_arg = args[i + 1]
      if dir_arg then
        config.map_output_dir = dir_arg
      end
    elseif arg == "--sim-map-size" then
      local size_arg = args[i + 1]
      if size_arg and tonumber(size_arg) then
        config.map_cell_size = tonumber(size_arg)
      end
    elseif arg == "--sim-show-scores" then
      config.show_placement_scores = true
    end
  end

  return config, run_count
end

--- Print simulation results in a formatted way
---@param results vibes.testing.SimulationResult[]
---@param summary table
local function print_simulation_results(results, summary)
  print("\n" .. string.rep("=", 60))
  print "HEADLESS SIMULATION RESULTS"
  print(string.rep("=", 60))

  -- Print summary
  print(string.format("Total Runs: %d", summary.total_runs))
  print(
    string.format(
      "Successful: %d (%.1f%%)",
      summary.successful_runs,
      summary.success_rate * 100
    )
  )
  print(string.format("Average Rounds: %.1f", summary.average_rounds))
  print(string.format("Average Final Health: %.1f", summary.average_health))
  print(string.format("Average Final Gold: %.1f", summary.average_gold))
  print(string.format("Average Towers Placed: %.1f", summary.average_towers))
  print(
    string.format("Average Cards Played: %.1f", summary.average_cards_played)
  )
  print(
    string.format(
      "Average Simulation Time: %.2fs",
      summary.average_simulation_time
    )
  )

  -- Print individual results if there are few enough
  if #results <= 10 then
    print "\nIndividual Results:"
    print(string.rep("-", 60))
    for i, result in ipairs(results) do
      local status = result.success and "SUCCESS" or "FAILED"
      print(
        string.format(
          "Run %d [%s]: Rounds=%d, Health=%d, Gold=%d, Towers=%d, Time=%.2fs",
          i,
          status,
          result.rounds_completed,
          result.final_health,
          result.final_gold,
          result.towers_placed,
          result.simulation_time
        )
      )
      if result.error_message then
        print(string.format("  Error: %s", result.error_message))
      end
    end
  end

  -- Print any failed runs
  local failed_runs = {}
  for i, result in ipairs(results) do
    if not result.success then
      table.insert(failed_runs, { index = i, result = result })
    end
  end

  if #failed_runs > 0 then
    print "\nFailed Runs:"
    print(string.rep("-", 60))
    for _, failed in ipairs(failed_runs) do
      print(
        string.format(
          "Run %d: %s",
          failed.index,
          failed.result.error_message or "Unknown error"
        )
      )
    end
  end

  print(string.rep("=", 60))
end

--- Print usage information for simulation commands
local function print_simulation_usage()
  print "\nHeadless Simulation Usage:"
  print "love . --runner-simulation [options]"
  print "\nOptions:"
  print "  --sim-seed N           Set random seed (default: random)"
  print "  --sim-rounds N         Set max rounds per simulation (default: 6)"
  print "  --sim-runs N           Number of simulations to run (default: 1)"
  print "  --sim-character NAME   Character to use (default: BLACKSMITH)"
  print "  --sim-strategy NAME    Placement strategy (default: balanced)"
  print "                         Options: entrance_focus, exit_block, path_choke, balanced"
  print "  --sim-level N          Starting level (default: 1)"
  print "  --sim-time-limit N     Time limit per simulation in seconds (default: 60)"
  print "  --sim-verbose          Enable detailed logging"
  print "  --sim-map              Generate map visualization image"
  print "  --sim-map-dir DIR      Directory to save map images (default: tmp/)"
  print "  --sim-map-size N       Cell size in pixels for map (default: 20)"
  print "  --sim-show-scores      Show placement scores on map"
  print "\nExamples:"
  print "  love . --runner-simulation --sim-runs 5 --sim-rounds 20"
  print "  love . --runner-simulation --sim-seed 12345 --sim-strategy entrance_focus"
  print "  love . --runner-simulation --sim-verbose --sim-time-limit 120"
  print "  love . --runner-simulation --sim-map --sim-show-scores --sim-map-size 30"
end

--- Check if simulation should run based on command line arguments
---@param args string[] Command line arguments
---@return boolean should_run
function SimulationRunner.should_run(args)
  for _, arg in ipairs(args) do
    if arg == "--runner-simulation" or arg == "--runner-sim" then
      return true
    end
  end
  return false
end

--- Run simulations based on command line arguments
---@param args string[] Command line arguments
function SimulationRunner.run(args)
  -- Check for help request
  for _, arg in ipairs(args) do
    if arg == "--sim-help" or arg == "--help" then
      print_simulation_usage()
      return
    end
  end

  local config, run_count = parse_simulation_args(args)

  -- If no seed specified, generate one
  if not config.seed then
    config.seed = os.time() % (16 ^ 8)
  end

  print(
    string.format(
      "Starting %d simulation(s) with seed %d...",
      run_count,
      config.seed
    )
  )
  print(
    string.format(
      "Config: rounds=%d, character=%s, strategy=%s, level=%d",
      config.max_rounds,
      config.character,
      config.placement_strategy,
      config.starting_level
    )
  )

  local start_time = love.timer.getTime()

  local results, summary
  if run_count == 1 then
    local result = HeadlessSimulator.run_simulation(config)
    results = { result }
    summary = {
      total_runs = 1,
      successful_runs = result.success and 1 or 0,
      success_rate = result.success and 1 or 0,
      average_rounds = result.rounds_completed,
      average_health = result.final_health,
      average_gold = result.final_gold,
      average_towers = result.towers_placed,
      average_cards_played = result.cards_played,
      average_simulation_time = result.simulation_time,
    }
  else
    results, summary =
      HeadlessSimulator.run_batch_simulations(config, run_count)
  end

  local total_time = love.timer.getTime() - start_time

  print_simulation_results(results, summary)
  print(string.format("\nTotal execution time: %.2fs", total_time))
end

return SimulationRunner
