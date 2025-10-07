--[[

GAME RULES:

Wave Progression:
- Every Level has 3 Main Waves.
- After the main wave, there is a roll for a SINGLE non-tower card.
- There are now 5 Bonus Waves.
  - Each bonus wave increases in difficulty and rarity.
  - Uncommon, Rare, **GEAR**, Epic, Legendary
  - Only The **GEAR** wave gives a chance for a roll for gear.
  - All the other bonus waves give a chance for a roll for a non-tower card at the rarity specified above.

- At any point after the main wave, the player may decide to move to the shop, and stop pursuing any bonus levels

- After you press start wave, you discard immediately and draw new cards (up to 5 by default).
- Start with 4 energy. Retained between waves. And you get 2 energy between waves.

--]]

local GameUI = require "ui.components.ui-game"
local SystemManager = require "vibes.systems"
local TotalDamageDealtDisplay =
  require "ui.components.player.total-damage-display"
local TrophySelectionAction = require "vibes.action.trophy-selection"
local createPlayerHUD = require "ui.components.player.hud"

---@class (exact) vibes.GameMode : vibes.BaseMode
---@field ui components.GameUI
---@field hud ui.components.player.HUD
---@field lifecycle RoundLifecycle
---@field systems vibes.SystemManager
---@field is_level_start boolean: Flag to track if this is the start of a new level
local GameMode = {}

function GameMode:enter()
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

  self.systems = SystemManager.new {
    systems = {
      require "vibes.systems.game-animation",
      PoisonPoolSystem,
      FirePoolSystem,
      require "vibes.systems.poison-system",
      require "vibes.systems.fire-system",
      require "vibes.systems.projectile-system",
      require "vibes.systems.damage-display",
    },
  }

  -- TODO: there could be orbs that affect this? Should find a way to calculate
  -- this maybe? I'm not sure.
  State.player.discards = Config.player.default_discards

  -- if game_ui == nil then
  --   game_ui = GameUI.new {}
  -- end

  self.ui = GameUI.new {}
  self.ui:reset()
  local total_damage_dealt_display = TotalDamageDealtDisplay.new {}
  total_damage_dealt_display:set_z(Z.MAX)

  self.ui:append_child(total_damage_dealt_display)

  UI.root:append_child(self.ui)

  ---@type hooks.BeforeLevelStart.Result
  local result = {
    discards = Config.player.default_discards,
    energy = Config:get_starting_energy_for_level(
      State.levels:get_current_level_number()
    ),
    level = level,
  }

  State:for_each_active_hook(
    function(item) return item.hooks.before_level_starts(item, result) end
  )

  -- Apply the energy from the hooks result to the player
  State.player.energy = result.energy
  State.player.discards = result.discards

  -- TODO: Z Index is a bit confusing here w/ the UI, should figure this out later
  -- and probably have a nice list somewhere with each of the z-indexes hard coded.

  self.hud = createPlayerHUD {}
  self.hud.z = self.ui.z + 1
  UI.root:append_child(self.hud)

  -- Flag that this is a level start (not just a wave start)
  self.is_level_start = true
  self.lifecycle = RoundLifecycle.PLAYER_PREP
end

function GameMode:exit()
  if self.systems and self.systems.destroy then
    self.systems:destroy()
  end

  if self.ui and self.ui.destroy then
    self.ui:destroy()
  end

  UI.root:remove_child(self.ui)
end

local external_lifecycles = {
  [RoundLifecycle.PLAYER_PROCESSING_DRAW] = true,
  [RoundLifecycle.TOWER_LEVELING] = true,
  [RoundLifecycle.TROPHY_SELECTION] = true,
}

function GameMode:update(dt)
  if State.is_paused then
    return
  end

  if external_lifecycles[self.lifecycle] then
    logger.trace(
      "vibes/modes/game.lua:update: skipping lifecycle: %s",
      self.lifecycle
    )
    return
  end

  if State.player.health <= 0 then
    self.lifecycle = RoundLifecycle.GAME_OVER
    EventBus:emit_after_level_end { level = State.levels:get_current_level() }
    return
  end

  local level = State.levels:get_current_level()

  -- Update towers first so they can create projectiles
  for _, tower in ipairs(State.towers) do
    tower:update(dt)
  end

  -- Update enemies first so projectiles can collide with their updated positions
  if self.lifecycle == RoundLifecycle.ENEMIES_SPAWNING then
    State.spawner:update()

    for _, enemy in ipairs(State.enemies) do
      enemy:update(dt)
    end

    self.hud:update(dt)

    if #State.enemies == 0 and State.spawner:is_done() then
      self.lifecycle = RoundLifecycle.ENEMIES_DEFEATED
      return
    end

    -- Update systems AFTER enemies have moved
    self.systems:update(dt)

    return
  end

  -- Update systems for other lifecycles
  self.systems:update(dt)

  if self.lifecycle == RoundLifecycle.PLAYER_PREP then
    level:on_draw()

    -- self.lifecycle = RoundLifecycle.PLAYER_PROCESSING_DRAW

    if #State.deck.draw_pile > 0 then
      ----
      ----
      ----
      ----
      ----
      -- Use guaranteed tower drawing if this is a level start
      if self.is_level_start then
        local cards_in_hand = #State.deck.hand
        local cards_to_draw =
          math.max(State.player.hand_size - cards_in_hand, 0)

        if cards_to_draw > 0 then
          State.deck:draw_cards_with_guaranteed_towers(cards_to_draw, 3)

          -- Trigger card draw animations for visual feedback
          local delay = 75
          for i = 1, cards_to_draw do
            Timer.oneshot(i * delay, function()
              -- Just trigger the visual effect, cards are already drawn
              EventBus:emit_card_draw {
                card = State.deck.hand[#State.deck.hand - cards_to_draw + i],
              }
            end)
          end
          Timer.oneshot(cards_to_draw * delay + 50, function()
            self.is_level_start = false -- Reset flag after level start
            self.lifecycle = RoundLifecycle.PLAYER_TURN
          end)
        end
      else
        State.deck:draw_hand()
        self.lifecycle = RoundLifecycle.PLAYER_TURN
      end
      ----
      ----
      ----
      ----
      ----
    else
      State.deck:_shuffle_discards_into_draw_pile()
      self.is_level_start = false -- Reset flag after level start
      State.deck:draw_hand()
      self.lifecycle = RoundLifecycle.PLAYER_TURN
    end

    return
  end

  if self.lifecycle == RoundLifecycle.ENEMIES_SPAWN_START then
    level:on_start()
    return self:start_wave()
  end

  if self.lifecycle == RoundLifecycle.ENEMIES_DEFEATED then
    level:on_end()
    self:complete_wave()

    return
  end

  if self.lifecycle == RoundLifecycle.WAVE_COMPLETE then
    local current_level = State.levels:get_current_level()
    local current_wave = State.levels.current_wave
    local completed_wave = current_wave - 1

    -- If we're on a main wave, we can just continue!
    if completed_wave < 3 then
      self.lifecycle = RoundLifecycle.PLAYER_PREP
      return
    end

    self.lifecycle = RoundLifecycle.TROPHY_SELECTION
    ActionQueue:add(TrophySelectionAction.new {
      current_completed_wave = completed_wave,
      on_choose_shop = function()
        self.lifecycle = RoundLifecycle.LEVEL_COMPLETE
      end,
      on_complete = function()
        if completed_wave == Config.ui.level.wave_count then
          self.lifecycle = RoundLifecycle.LEVEL_COMPLETE
        else
          self.lifecycle = RoundLifecycle.PLAYER_PREP
        end
      end,
    })
  end

  if self.lifecycle == RoundLifecycle.LEVEL_COMPLETE then
    level:on_complete()
    ActionQueue:clear()
    EventBus:emit_after_level_end { level = level }
    if State.levels:advance_to_next_level() then
      State.deck:reset()
      State.mode = ModeName.SHOP
    else
      State.mode = ModeName.BEAT_GAME
    end
    return
  end
end

function GameMode:start_wave()
  self.ui.hand:discard_hand()
  State.deck:draw_hand()

  logger.info "GameMode:start_wave() called"
  local wave = State.levels:get_current_wave()
  logger.info "Successfully got current wave, starting spawn"
  State.spawner:spawn_wave(wave)

  State:for_each_active_hook(
    function(item) item.hooks.before_wave_starts(item, wave) end
  )

  self.lifecycle = RoundLifecycle.ENEMIES_SPAWNING
end

--- Handle completion of a wave
function GameMode:complete_wave()
  State.levels:complete_wave()

  for i = #State.auras, 1, -1 do
    if State.auras[i].duration == EffectDuration.END_OF_WAVE then
      table.remove(State.auras, i)
    end
  end

  for _, tower in ipairs(State.towers) do
    for i = #tower.enhancements, 1, -1 do
      if tower.enhancements[i].duration == EffectDuration.END_OF_WAVE then
        table.remove(tower.enhancements, i)
      end
    end
  end

  self.lifecycle = RoundLifecycle.WAVE_COMPLETE
end

function GameMode:calculate_interest()
  local interest_threshold = 200 -- Increased from 100
  local interest_rate = 0.01 -- 1% interest (reduced from 2% for 50% less gold)
  local interest_earned = 0

  if State.player.gold >= interest_threshold then
    interest_earned = math.floor(State.player.gold * interest_rate)
    State.player.gold = State.player.gold + interest_earned
    -- Store interest info for display
    State.last_interest_earned = interest_earned
    State.interest_calculated = true
  else
    State.interest_calculated = false
    State.last_interest_earned = 0
  end
end

function GameMode:draw()
  love.graphics.setColor(0.25, 0.25, 0.25, 1)
  love.graphics.rectangle("fill", 0, 0, 1280, 720)

  State.levels:get_current_level():draw()

  self.systems:draw()
end

function GameMode:_try_place_card() end

function GameMode:mousemoved() end

---Increase game speed by cycling through available speeds
---@return boolean
function GameMode:increase_game_speed()
  SpeedManager:next_speed()
  return true
end

---Decrease game speed by cycling through available speeds
---@return boolean
function GameMode:decrease_game_speed()
  SpeedManager:cycle_to_previous_speed()
  return true
end

---@param key string
function GameMode:keypressed(key)
  -- Allow restarting with R key when game is over
  --
  if key == "r" and self.lifecycle == RoundLifecycle.GAME_OVER then
    RESET_STATE()
    return true
  end

  if key == "return" then
    if self.lifecycle == RoundLifecycle.LEVEL_COMPLETE then
      error "return"
      -- State.levels:reset_level_state()
      --
      -- if State.levels:advance_to_next_level() then
      --   self.lifecycle = RoundLifecycle.START
      -- else
      --   -- State.mode = GameModes.BEAT_GAME
      -- end
      -- return
    end
  elseif key == "space" then
    if self.lifecycle == RoundLifecycle.PLAYER_TURN then
      return self:start_wave()
    else
      -- Cycle to next speed when not in player turn
      return self:increase_game_speed()
    end
  end

  -- Game speed controls with + and - keys
  if key == "+" or key == "kp+" then
    return self:increase_game_speed()
  elseif key == "-" or key == "kp-" then
    return self:decrease_game_speed()
  end
end

return require("vibes.base-mode").wrap(GameMode)
