package.path = package.path .. ";packages/?.lua;packages/?/init.lua"

-- WHETHER THIS IS A PRODUCTION BUILD!
PRODUCTION = false

-- Note: We use Lua's built-in assert, not luassert
-- luassert is only needed for testing, the game only uses basic assert(condition, "message")

-- Load globals
require "vibes.prelude"
require "ui.components.ui"

-- Begin loading sequence
local Commander = require "vibes.commander"
local GameState = require "vibes.data.gamestate"
local PauseAction = require "vibes.action.pause"
local SimulationRunner = require "vibes.testing.simulation-runner"
local TextInputPopUp = require "ui.components.text-input-popup"
local arglib = require "vendor.args"

local pcall_with_report = function(cb)
  local ok, msg = xpcall(cb, debug.traceback)
  if not ok and not PRODUCTION then
    print(msg)
  end
end

---@type table<ModeName, vibes.BaseMode>
MODES = {}

WINDOW_STATUS = {
  translateX = 0,
  translateY = 0,
  scale = 2,
  width = Config.window_size.width,
  height = Config.window_size.height,
}

---@type vibes.SystemManager
local global_systems
local get_global_systems = function()
  return require("vibes.systems").new {
    systems = {
      require "vibes.systems.animation-system",
    },
  }
end

local previous_mode = "__unset__"
--- @return vibes.BaseModeupgrade-icon
local function get_mode()
  local mode_str = State.mode

  if previous_mode ~= mode_str then
    local previous = MODES[previous_mode]

    if previous then
      previous:exit()
    end

    logger.debug("previous mode: %s", previous_mode)

    State.last_mode = previous_mode

    local current = MODES[mode_str]

    -- First, reset the UI
    UI:reset(Config.window_size.width, Config.window_size.height)

    State.developer_console = TextInputPopUp.new {
      pos_x = Config.window_size.width / 3,
      pos_y = Config.window_size.height / 3,
      prompt_text = "Developer Console",
      character_limit = 300,
      on_enter = function(txt) Commander.execute(txt) end,
      validate_input = function(_) return true end,
    }

    State.developer_console:set_hidden(true)

    -- Append Pause Menu on Reset
    UI.root:append_child(State.developer_console)

    current:enter()

    logger.debug("current mode: %s", mode_str)
  end

  ---@diagnostic disable-next-line
  previous_mode = mode_str
  return MODES[mode_str]
end

local load_all_modes = function()
  local mode_modules = require "vibes.enum.mode-name"
  for _, file in pairs(require("vibes.enum").values(mode_modules)) do
    logger.info("requiring mode: %s", file)
    MODES[file] = require(file)
    -- if file == mode_modules.GAME then
    --   GAME = MODES[file]
    -- end
  end
  logger.info "Finished loading modules."
end

RESET_STATE = function()
  Asset = require "vibes.asset"
  State = GameState.new()

  load_all_modes()

  global_systems = get_global_systems()
end

---@param name string
---@param default_value number
---@return number
local function get_arg_value(name, default_value)
  local has, idx = arglib.contains_flag(arg, name)
  return has and tonumber(arg[idx + 1]) or default_value
end

local start_time = os.time()

function love.load(arg)
  love.filesystem.setIdentity "Mordoria"
  love.mouse.setVisible(false)

  math.randomseed(start_time)

  -- Adam likes this, do not change.
  -- It makes the pixel art look better.
  -- love.graphics.setDefaultFilter("nearest", "nearest")
  love.graphics.setDefaultFilter("linear", "linear", 16)
  -- if your code was optimized for fullHD:
  WINDOW_STATUS.translateX = 0
  WINDOW_STATUS.translateY = 0
  WINDOW_STATUS.scale = 2
  WINDOW_STATUS.width = Config.window_size.width
  WINDOW_STATUS.height = Config.window_size.height

  local width, height = love.graphics.getDimensions()
  -- Use fullscreen by default on first launch, unless in development mode
  local should_be_fullscreen = PRODUCTION or (Config.window_size.mode == "fullscreen")
  love.window.setMode(width, height, {
    resizable = not PRODUCTION,
    borderless = not PRODUCTION,
    fullscreen = should_be_fullscreen,
  })

  -- added to specify display to load on (for debugging)
  -- getting desktop dimensions as opening caused it to shoot to the bottom right of my screen
  -- and I ain't got time for that.
  local desktop_width, desktop_height = love.window.getDesktopDimensions(1)
  local window_x = (desktop_width - width) / 2
  local window_y = (desktop_height - height) / 2

  love.window.setPosition(window_x, window_y)

  if os.getenv "USER" == "defyus" then
    -- love.window.setPosition(5300, 310, 1)
  elseif os.getenv "USER" == "tjdevries" then
    -- Config.player.default_energy = 100
    love.mouse.setVisible(true)
    -- local scale = 1.5
    -- love.window.setMode(scale * 1920, scale * 1080, {
    --   resizable = true,
    --   borderless = false,
    --   fullscreen = false,
    --   centered = false,
    -- })
    logger.level = logger.DEBUG
  end

  -- Get all mode files from vibes/modes
  local test_game = arglib.contains_flag(arg, "--test-game")
  local test_level_up = arglib.contains_flag(arg, "--test-level-up")
  local debug_mode = arglib.contains_flag(arg, "--debug")
  local profiler = arglib.contains_flag(arg, "--profile")

  local test_upgrade_ui = arglib.contains_flag(arg, "--test-upgrade-ui")
  local test_card = arglib.contains_flag(arg, "--test-card")
  local test_ui = arglib.contains_flag(arg, "--test-ui")
  local test_teej_animation = arglib.contains_flag(arg, "--test-teej-animation")
  local test_tileset = arglib.contains_flag(arg, "--test-tileset")
  local test_inventory = arglib.contains_flag(arg, "--test-inventory")
  local test_tower_details = arglib.contains_flag(arg, "--test-tower-details")
  local test_canvas = arglib.contains_flag(arg, "--test-canvas")
  local test_forge = arglib.contains_flag(arg, "--test-forge")
  local test_gear_start = arglib.contains_flag(arg, "--test-gear-start")
  local skip_gear = arglib.contains_flag(arg, "--skip-gear")
  local tower_level = get_arg_value("--tower-level", 1)
  local test_shop = arglib.contains_flag(arg, "--test-shop")
  local test_card_distribution =
    arglib.contains_flag(arg, "--test-card-distribution")
  local test_wave = get_arg_value("--test-wave", 1)
  local test_level = get_arg_value("--test-level", 1)
  local surprise_mode = arglib.contains_flag(arg, "--surprise")

  -- Set test values in Config if provided
  if test_wave > 1 or test_level > 1 then
    Config.test_wave = test_wave
    Config.test_level = test_level
  end

  local test_ed = arglib.contains_flag(arg, "--test-ed")
  local test_teej = arglib.contains_flag(arg, "--test-teej")

  if test_ed then
    test_game = true
  end

  if test_level_up then
    test_game = true
  end

  Config.debug.enabled = test_game or debug_mode

  if arglib.contains_flag(arg, "--editor") then
    error "TODO: implement editor mode"
  elseif test_shop then
    Config.starting_mode = ModeName.SHOP
    Config.player.starting_gold = 5000
  elseif arglib.contains_flag(arg, "--test-beat-game") then
    Config.starting_mode = ModeName.BEAT_GAME
  end

  Config.starting_level = get_arg_value("--level", 1)
  Config.selected_levels = arglib.get_levels(arg)
  Config.tower_level = tower_level

  -- If no levels are specified, use all available levels (let LevelManager handle it)
  if not Config.selected_levels or #Config.selected_levels == 0 then
    Config.selected_levels = nil -- This will make LevelManager use its available_levels array
    Config.starting_level = 1
  end

  -- If specific levels are provided but no --level is set, start at index 1
  if Config.selected_levels and #Config.selected_levels > 0 then
    local provided_level_flag = arglib.contains_flag(arg, "--level")
    if not provided_level_flag then
      Config.starting_level = 1
    end
  end

  if test_gear_start then
    Config.debug.enabled = true
    Config.starting_mode = ModeName.TEST_GEAR_SELECT
    Config.starting_character = CharacterKind.BLACKSMITH
  elseif test_game then
    Config.debug.enabled = true
    Config.starting_mode = ModeName.GAME
    Config.starting_character = CharacterKind.BLACKSMITH
  end

  if test_teej then
    Config.player.default_energy = 100
    -- require("vibes.tower.tower-archer")._base_stats.damage.base = 1000
    -- require("vibes.tower.tower-archer")._base_stats.damage.mult = 1
    -- require("vibes.tower.tower-archer")._base_stats.damage.value = 1000
  end

  if test_level_up then
    require("vibes.enemy.enemy-bat")._properties.xp_reward = 200
    require("vibes.tower.tower-archer")._base_stats.damage.base = 20
  end

  -- Set surprise mode flag before resetting state
  local surprise_mode_flag = surprise_mode

  RESET_STATE()

  -- Apply surprise mode flag after state reset
  State.surprise_mode = surprise_mode_flag

  Config:resize()

  if test_card_distribution then
    local CardFactory = require "vibes.factory.card-factory"
    local cards = {}
    for i = 1, 25 do
      table.insert(cards, CardFactory.random_card())
    end

    -- Render a bar graph of the different rarities in the 100 random cards

    -- Count rarities
    local rarity_counts = {}
    for _, card in ipairs(cards) do
      local rarity = card.rarity or "UNKNOWN"
      rarity_counts[rarity] = (rarity_counts[rarity] or 0) + 1
    end

    -- Sort rarities for consistent display order
    local sorted_rarities = {}
    for rarity in pairs(rarity_counts) do
      table.insert(sorted_rarities, rarity)
    end
    table.sort(sorted_rarities)

    -- Bar graph parameters
    local max_bar_width = 40
    local max_count = 0
    for _, count in pairs(rarity_counts) do
      if count > max_count then
        max_count = count
      end
    end

    -- Count card kinds
    local kind_counts = {}
    for _, card in ipairs(cards) do
      local kind = card.kind or "UNKNOWN"
      kind_counts[kind] = (kind_counts[kind] or 0) + 1
    end

    -- Sort kinds for consistent display order
    local sorted_kinds = {}
    for kind in pairs(kind_counts) do
      table.insert(sorted_kinds, kind)
    end
    table.sort(sorted_kinds)

    -- Bar graph parameters for kinds
    local max_kind_bar_width = 40
    local max_kind_count = 0
    for _, count in pairs(kind_counts) do
      if count > max_kind_count then
        max_kind_count = count
      end
    end

    print "\nCard Kind Distribution (Bar Graph):"
    -- Sort kinds by count descending, then by kind name for ties
    table.sort(sorted_kinds, function(a, b)
      local ca, cb = kind_counts[a], kind_counts[b]
      if ca ~= cb then
        return ca > cb
      else
        return tostring(a) < tostring(b)
      end
    end)
    for _, kind in ipairs(sorted_kinds) do
      local count = kind_counts[kind]
      local bar_len =
        math.floor((count / max_kind_count) * max_kind_bar_width + 0.5)
      local bar = string.rep("█", bar_len)
      print(string.format("%-12s | %-3d %s", tostring(kind), count, bar))
    end
    print "\n"

    print "\nRarity Distribution (Bar Graph):"
    -- Sort rarities by count descending, then by rarity name for ties
    table.sort(sorted_rarities, function(a, b)
      local ca, cb = rarity_counts[a], rarity_counts[b]
      if ca ~= cb then
        return ca > cb
      else
        return tostring(a) < tostring(b)
      end
    end)
    for _, rarity in ipairs(sorted_rarities) do
      local count = rarity_counts[rarity]
      local bar_len = math.floor((count / max_count) * max_bar_width + 0.5)
      local bar = string.rep("█", bar_len)
      print(string.format("%-12s | %-3d %s", tostring(rarity), count, bar))
    end
    print "\n"

    -- For each card kind, print a rarity bar graph
    local all_kinds = {}
    for kind in pairs(kind_counts) do
      table.insert(all_kinds, kind)
    end
    table.sort(all_kinds, function(a, b) return tostring(a) < tostring(b) end)

    for _, kind in ipairs(all_kinds) do
      -- Gather rarity counts for this kind
      local rarity_counts_for_kind = {}
      local max_count_for_kind = 0
      for _, card in ipairs(cards) do
        if card.kind == kind then
          local rarity = card.rarity or "UNKNOWN"
          rarity_counts_for_kind[rarity] = (rarity_counts_for_kind[rarity] or 0)
            + 1
          if rarity_counts_for_kind[rarity] > max_count_for_kind then
            max_count_for_kind = rarity_counts_for_kind[rarity]
          end
        end
      end

      -- Only print if there are cards of this kind
      if max_count_for_kind > 0 then
        print(
          string.format(
            "Rarity Distribution for Kind: %s (Bar Graph):",
            tostring(kind)
          )
        )
        -- Sort rarities by count descending, then by name
        local rarities = {}
        for rarity in pairs(rarity_counts_for_kind) do
          table.insert(rarities, rarity)
        end
        table.sort(rarities, function(a, b)
          local ca, cb = rarity_counts_for_kind[a], rarity_counts_for_kind[b]
          if ca ~= cb then
            return ca > cb
          else
            return tostring(a) < tostring(b)
          end
        end)
        for _, rarity in ipairs(rarities) do
          local count = rarity_counts_for_kind[rarity]
          local bar_len =
            math.floor((count / max_count_for_kind) * max_bar_width + 0.5)
          local bar = string.rep("█", bar_len)
          print(string.format("%-12s | %-3d %s", tostring(rarity), count, bar))
        end
        print "\n"
      end
    end

    -- Shuffle all the cards we drew and print the top 5
    local shuffled = {}
    for _, card in ipairs(cards) do
      table.insert(shuffled, card)
    end
    -- Fisher-Yates shuffle
    for i = #shuffled, 2, -1 do
      local j = math.random(i)
      shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
    end
    print "Top 5 cards after shuffling:"
    for i = 1, math.min(5, #shuffled) do
      local card = shuffled[i]
      print(
        string.format(
          "%d. %s (Kind: %s, Rarity: %s)",
          i,
          tostring(card.name or "<unnamed>"),
          tostring(card.kind or "<unknown>"),
          tostring(card.rarity or "<unknown>")
        )
      )
    end

    love.event.quit(0)
    return
  end

  if test_gear_start then
    State.mode = ModeName.TEST_GEAR_SELECT
    State.selected_character = CharacterKind.BLACKSMITH
  elseif test_game then
    State.mode = ModeName.GAME
    State.selected_character = CharacterKind.BLACKSMITH
  end

  if test_game and test_ed then
    State.deck:reset()
    State.deck.hand = {}
    State.player.energy = 10000

    --  for i = 0, 3, 1 do
    --    local ember = require("vibes.card.card-tower-emberwatch").new {}
    --    ember:level_up_to((2 * i) or 1)
    --    State.deck:add_card(ember)
    --  end

    --    for i = 0, 3, 1 do
    --      local lightning = require("vibes.card.card-tower-lightning").new {}
    --      lightning:level_up_to((2 * i) or 1)
    --      State.deck:add_card(lightning)
    --    end
    --
    --    for i = 0, 3, 1 do
    --      local poison = require("vibes.card.card-tower-poisoned-arrow").new {}
    --      poison:level_up_to((2 * i) or 1)
    --      State.deck:add_card(poison)
    --    end
    --
    --   for i = 0, 3, 1 do
    --     local earth = require("vibes.card.card-tower-earth").new {}
    --     earth:level_up_to((2 * i) or 1)
    --     State.deck:add_card(earth)
    --   end

    --   for i = 0, 3, 1 do
    --     local catapault = require("vibes.card.card-tower-catapault").new {}
    --     catapault:level_up_to((2 * i) or 1)
    --     State.deck:add_card(catapault)
    --   end

    for i = 0, 3, 1 do
      local windmill = require("vibes.card.card-tower-windmill").new {}
      windmill:level_up_to((2 * i) or 1)
      State.deck:add_card(windmill)
    end

    -- Add a ton of Git Stash aura cards for testing
    --    for i = 1, 20, 1 do
    --      local git_stash = require("vibes.card.aura.git-stash").new()
    --      State.deck:add_card(git_stash)
    --    end

    -- Add Bunni's Wrath enhancement card for testing
    local bunnis_wrath = require("vibes.card.enhancement.bunnis-wrath").new()
    State.deck:add_card(bunnis_wrath)

    -- Add basic archer tower to hand for testing
    local archer = require("vibes.card.card-tower-archer").new {}
    table.insert(State.deck.hand, archer)
  end

  if test_shop then
    local GEAR = require "gear.state"
    State.gear_manager:assign_gear_to_slot(GEAR.fire_hat, GearSlot.HAT)
    State.gear_manager:assign_gear_to_slot(
      GEAR.moustache_comb,
      GearSlot.TOOL_LEFT
    )
    State.gear_manager:assign_gear_to_slot(GEAR.hot_potato, GearSlot.TOOL_RIGHT)
    State.gear_manager:assign_gear_to_slot(GEAR.snakeskin_boots, GearSlot.SHOES)
  end

  if test_game and not test_gear_start and not skip_gear then
    -- Add ALL available gear items to test the gear system comprehensively
    local GEAR = require "gear.state"

    -- Equipped slots - one item per slot based on gear type
    -- HAT slot
    -- State.gear_manager:assign_gear_to_slot(GEAR.fire_hat, GearSlot.HAT)

    -- RING slots (2 available)
    State.gear_manager:assign_gear_to_slot(GEAR.energy_ring, GearSlot.RING_LEFT)

    -- TOOL slots (2 available)
    State.gear_manager:assign_gear_to_slot(GEAR.trashs_wine, GearSlot.TOOL_LEFT)
    State.gear_manager:assign_gear_to_slot(
      GEAR.trashs_chips,
      GearSlot.TOOL_RIGHT
    )

    -- PANTS slot
    State.gear_manager:assign_gear_to_slot(GEAR.strong_tearaway_pants, GearSlot.PANTS)

    -- SHOES slot
    State.gear_manager:assign_gear_to_slot(GEAR.snakeskin_boots, GearSlot.SHOES)

    -- INVENTORY slots for testing additional gear
    State.gear_manager:assign_gear_to_slot(GEAR.gravity, GearSlot.INVENTORY_ONE)
    State.gear_manager:assign_gear_to_slot(
      GEAR.sunflower,
      GearSlot.INVENTORY_TWO
    )

    -- Log all available gear for reference
    logger.info "Test Shop: Added all available gear items:"
    logger.info "  Equipped: fire_hat, energy_ring, attack_speed_ring, moustache_comb, potato, snakeskin_boots"
    logger.info "  Inventory: defense_ring, health_ring, rubiks_cube, split_keyboard"
    logger.info "  Remaining: spinner_hat, top_hat, heavy_boots, quiet_baby, tactician_manual, chaos_crown"

    -- local poison_tower = require("vibes.card.card-tower-poisoned-arrow").new {}
    -- poison_tower:level_up_to(7)

    -- State.deck:add_card(poison_tower)

    -- poison_tower = require("vibes.card.card-tower-poisoned-arrow").new {}
    -- State.deck:add_card(poison_tower)
    -- -- poison_tower:level_up_to()

    -- Config.player.default_energy = 1000
  end

  if test_upgrade_ui then
    State.mode = ModeName.TEST_UPGRADE_UI
  end

  if test_card then
    State.mode = ModeName.TEST_CARD
  end

  if State.debug then
    State.player.gold = 1000000
  end

  if profiler then
    love.profiler = require "vendor.profile"
    love.profiler.start()
  end

  if test_teej_animation then
    State.mode = ModeName.TEST_TEEJ_ANIMATION
  end

  if test_teej then
    -- State.gear_manager:assign_gear_to_slot(GEAR.top_hat, GearSlot.HAT)
    -- State.gear_manager:assign_gear_to_slot(GEAR.energy_ring, GearSlot.RING_LEFT)
    -- State.gear_manager:assign_gear_to_slot(GEAR.chaos_crown, GearSlot.HAT)
    State.gear_manager:assign_gear_to_slot(GEAR.trashs_wine, GearSlot.TOOL_LEFT)
    State.gear_manager:assign_gear_to_slot(
      GEAR.trashs_chips,
      GearSlot.TOOL_RIGHT
    )
  end

  if test_ui then
    State.mode = ModeName.TEST_UI
  end

  if test_tileset then
    State.mode = ModeName.TEST_TILESET
  end

  if test_inventory then
    State.mode = ModeName.TEST_INVENTORY
    State.selected_character = CharacterKind.BLACKSMITH
  end

  -- State.mode = ModeName.TEST_TOWER_DETAILS
  -- TODO: REMOVE TESTING TOWERDETAILS
  if test_tower_details then
    State.mode = ModeName.TEST_TOWER_DETAILS
  end

  if test_forge then
    State.mode = ModeName.TEST_FORGE
  end

  if test_canvas then
    State.mode = ModeName.TEST_CANVAS
  end

  if
    arglib.contains_flag(arg, "--runner")
    or arglib.contains_flag(arg, "--runner-headless")
  then
    require("tests.runner").go(arg)
    return
  end
  if os.getenv "USER" == "defyus" then
    State.characters[1].starter.gold = 10000000
    Config.player.starting_gold = 1000000
    -- love.window.setPosition(5300, 310, 1)
  end
  -- Check if we should run simulations instead
  if SimulationRunner.should_run(arg) then
    SimulationRunner.run(arg)
    love.event.quit(0)
    return
  end
end

love.frame = 0

local memory = collectgarbage "count"

local track_time = function(name, cb)
  local before_func = love.timer.getTime()
  cb()
  local after_func = love.timer.getTime()
  if after_func - before_func > 0.02 then
    logger.debug("  long func: %s: %0.2f", name, after_func - before_func)
  end
end

function love.update(dt)
  -- dt = dt / 10

  love.frame = love.frame + 1
  if love.profiler then
    if love.frame % 10 == 0 then
      love.report = love.profiler.report(20)
      love.profiler.reset()
    end
  end

  -- Handle game speed - the time system now handles this internally
  local time = require "vibes.engine.time"
  Timer.update_realtime(dt)

  local iterations = State.game_speed
  if iterations < 1 then
    iterations = 1
  end

  pcall_with_report(function()
    for _ = 1, iterations do
      if State.game_speed < 1 then
        dt = dt * State.game_speed
      end

      local modified_dt = dt
      local current_dt = time.update(modified_dt)

      Timer.update_gametime(dt)

      State:update(current_dt)
      ActionQueue:update(current_dt)
      UI:update(current_dt)

      get_mode():update(current_dt)

      global_systems:update(current_dt)
    end
  end)

  track_time("GC", function()
    if love.frame % Config.gc_timing == 0 then
      collectgarbage "collect"
      memory = collectgarbage "count"
      love.graphics.setFont(Asset.fonts.typography.h1)
      love.graphics.setColor(Colors.black:get())
      love.graphics.print(string.format("Memory: %d", memory), 0, 0, 0)
    end
  end)

  -- Do we need this for some reason?
  -- BAD FPS WARNING
  if dt > 1 / 30 then
    logger.debug("love.update: LONG DT: %0.2f", dt)
  end
end

function love.draw()
  local TIME = require "vibes.engine.time"
  TIME.frame = TIME.frame + 1

  love.graphics.translate(WINDOW_STATUS.translateX, WINDOW_STATUS.translateY)
  love.graphics.scale(WINDOW_STATUS.scale)
  love.graphics.push()

  pcall_with_report(function()
    get_mode():draw()
    UI:draw()
    State.mouse_object:draw()
  end)

  love.graphics.pop()
  -- love.graphics.setScissor()

  -- require("tests.runner").draw()
  -- love.graphics.setColor(1, 0, 0, 1)
  -- love.graphics.setFont(Asset.fonts.default_16)
  -- love.graphics.print(string.format("Memory: %.2f KB", memory), 20, 20, 0)
  -- love.graphics.print(string.format("FPS: %d", love.timer.getFPS()), 20, 40, 0)
  -- if love.report then
  --   love.graphics.setColor(0, 0, 0, 1)
  --   love.graphics.print(love.report, 20, 250, 0)
  -- end
end

function love.keypressed(key)
  pcall_with_report(function()
    -- This had the stat's selected_card as the condition, but I removed that.
    if key == "escape" then
      if State.focused_text_box ~= nil then
        State.focused_text_box:set_hidden(true)
        State.focused_text_box = nil
        return
      else
        -- Clear persistent tooltips first
        TooltipManager:handle_escape_key()

        if #ActionQueue.items == 0 then
          State.is_paused = true
          ActionQueue:add(PauseAction.new {})
        end
        return
      end
    end

    -- Developer console toggle (Ctrl+`)
    if
      key == "`"
      and (love.keyboard.isDown "lctrl" or love.keyboard.isDown "rctrl")
    then
      if State.developer_console then
        State.developer_console:set_hidden(
          not State.developer_console:is_hidden()
        )
        State.is_paused = State.developer_console:is_hidden()
        State.focused_text_box = State.developer_console.text_box
      end
      return
    end

    if State.focused_text_box ~= nil then
      State.focused_text_box:keypressed(key)
    end

    if key == "capslock" then
      key = "lctrl"
    end

    local current_mode = State.mode

    if key == "r" or key == "R" then
      logger.warn "reloading"
      local mode_str = State.mode
      get_mode():exit()

      local current_level = State.levels.current_level_idx

      require("vibes.reload").reload_all()
      -- load_all_modes()

      -- hot reloading breaks with game state, but it mostly resets the level-ish.
      --   Probably need to save a few other keys (like level, etc)
      State.mode = mode_str
      State.levels = require("vibes.level.manager").new {
        starting_level = current_level,
        available_levels = Config.selected_levels,
      }

      MODES[ModeName.TEST_UI] = require "vibes.modes.test-ui"

      UI:reset(Config.window_size.width, Config.window_size.height)
      get_mode():enter()
      return
    end

    if MODES[current_mode]:keypressed(key) then
      return
    end
  end)
end

---@param x number
---@param y number
local function mousedownscale(x, y)
  x = x or 0
  y = y or 0

  State.mouse.x =
    math.floor((x - WINDOW_STATUS.translateX) / WINDOW_STATUS.scale + 0.5)

  State.mouse.y =
    math.floor((y - WINDOW_STATUS.translateY) / WINDOW_STATUS.scale + 0.5)
end

function love.mousepressed(x, y, button)
  mousedownscale(x, y)

  pcall_with_report(function()
    -- Handle click-away for persistent tooltips
    if button == 1 then -- Left mouse button
      TooltipManager:handle_click_away(State.mouse.x, State.mouse.y)
    end

    State.mouse_object:mousepressed(button)
    UI:mousepressed(button, State.mouse.x, State.mouse.y)
  end)
end

function love.mousereleased(x, y, button)
  mousedownscale(x, y)

  pcall_with_report(function()
    State.mouse_object:mousereleased(button)
    UI:mousereleased(button, State.mouse.x, State.mouse.y)
  end)
end

function love.mousemoved(x, y)
  if not State or not State.mouse then
    return
  end

  mousedownscale(x, y)

  pcall_with_report(function() UI:mousemoved(State.mouse.x, State.mouse.y) end)
end

function love.textinput(text) get_mode():textinput(text) end
function love.resize(_w, _h) Config:resize() end
function love.quit() love.audio.stop() end
