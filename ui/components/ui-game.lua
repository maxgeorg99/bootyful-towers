local ButtonElement = require "ui.elements.button"
local Chip = require "ui.elements.chip"
local CurrentWaveIndicator = require "ui.components.wave.current-wave-indicator"
local DiscardButton = require "ui.components.game.discard-button"
local EnemySpawned = require "ui.components.enemy.spawned"
local NextWavePreview = require "ui.components.wave.next-wave-preview"
local PathWavePreview = require "ui.components.wave.path-wave-preview"
local PendingTower = require "ui.components.tower.pending-tower"
local PileElement = require "ui.components.pile"
local PlaceBox = require "ui.components.place_box"
local PlacedTower = require "ui.components.tower.placed-tower"
local StartRound = require "vibes.action.start-round"
local ViewPileAction = require "vibes.action.view-pile"

---@class components.GameUI.Opts

---@class (exact) components.GameUI : Element
---@field new fun( opts: components.GameUI.Opts)
---@field init fun(self:components.GameUI, opts: components.GameUI.Opts)
---@field enemy_tower_children Element
---@field current_wave_indicator components.CurrentWaveIndicator
---@field next_wave_preview components.NextWavePreview
---@field play_button elements.Button
---@field discard_all_button elements.Button
---@field time_multiplier_button elements.SpeedButton
---@field time_multiplier_button_toggle elements.SpeedToggleButton
---@field draw_pile components.Pile
---@field discard_pile components.Pile
---@field exhausted_pile components.Pile
---@field hand components.Hand
---@field energy_display components.EnergyDisplay
---@field _dispose_enemy_spawned fun(): nil
---@field _dispose_enemy_death fun(): nil
---@field _dispose_enemy_reached fun(): nil
---@field _dispose_tower_placed fun(): nil
local GameUI = class("components.GameUI", { super = Element })

---@param opts components.GameUI.Opts
function GameUI:init(opts)
  validate(opts, {})

  Element.init(self, Box.fullscreen())

  self.name = "GameUI"

  local LowerThird = require "ui.components.lower-third"
  self:append_child(LowerThird.new {
    z = Z.LOWER_THIRD,
  })

  local NoopElement = require "ui.components.noop"
  self.enemy_tower_children = NoopElement.new(Box.fullscreen())
  self:append_child(self.enemy_tower_children)

  -- Create current wave indicator in top-right area (next to next wave preview)
  self:_setup_current_wave_indicator()

  -- Create next wave preview in top-right corner
  self:_setup_next_wave_preview()

  -- Create per-path wave previews
  self:_setup_path_wave_previews()

  self:_setup_buttons()
  self:_setup_time_multiplier_button()
  self:_setup_cards()
  self:_setup_energy_display()
  self:_setup_discard_all_button()

  local ReadOnlyThreeByThreeGear =
    require "ui.components.inventory.readonly-three-by-three-gear"
  self:append_child(ReadOnlyThreeByThreeGear.new {
    z = Z.GEAR_DISPLAY,
  })

  -- TODO: Might actually make more sense to move this to global_events,
  -- and then we don't have to worry about creating copies/duplicates of
  -- the UI class. I don't know if it makes a difference though.
  self._dispose_enemy_spawned = EventBus:listen_enemy_spawned(
    function(e) self:_add_enemy(e.enemy) end
  )
  self._dispose_enemy_death = EventBus:listen_enemy_death(
    function(e) self:_remove_enemy(e.enemy) end
  )
  self._dispose_enemy_reached = EventBus:listen_enemy_reached_end(
    function(e) self:_remove_enemy(e.enemy) end
  )
  self._dispose_tower_placed = EventBus:listen_tower_placed(
    function(e) self:_add_tower(e.tower) end
  )
end

function GameUI:reset()
  self.enemy_tower_children:remove_all_children()

  -- Clean up path previews when resetting (e.g., switching levels)
  if self.path_wave_previews then
    for path_id, preview in pairs(self.path_wave_previews) do
      self:remove_child(preview)
    end
    self.path_wave_previews = {}
  end

  -- TODO: Reset the deck?
end

--- Properly unregister listeners and clean up
function GameUI:destroy()
  if self._dispose_enemy_spawned then
    self._dispose_enemy_spawned()
  end
  if self._dispose_enemy_death then
    self._dispose_enemy_death()
  end
  if self._dispose_enemy_reached then
    self._dispose_enemy_reached()
  end
  if self._dispose_tower_placed then
    self._dispose_tower_placed()
  end
  self._dispose_enemy_spawned = nil
  self._dispose_enemy_death = nil
  self._dispose_enemy_reached = nil
  self._dispose_tower_placed = nil

  -- Note: Element base has no destroy; children removal handled elsewhere
end

function GameUI:_mouse_moved(evt, x, y)
  -- TODO: Is this really necessary?
  self.enemy_tower_children:mouse_moved(evt, x, y)
end

---@param enemy vibes.Enemy
function GameUI:_remove_enemy(enemy)
  for _, el in ipairs(self.enemy_tower_children.children) do
    if EnemySpawned.is(el) then
      local enemy_ui = el --[[@as components.EnemySpawned]]
      if enemy_ui.enemy.id == enemy.id then
        enemy_ui:destroy()
        return
      end
    end
  end
end

---@param enemy vibes.Enemy
function GameUI:_add_enemy(enemy)
  local enamy_ui = EnemySpawned.new(enemy)
  self.enemy_tower_children:append_child(enamy_ui)
end

---@param tower vibes.TowerCard
function GameUI:_add_tower(tower)
  local placed_tower = PlacedTower.new(tower)
  self.enemy_tower_children:append_child(placed_tower)
end

---@param tower vibes.Tower
---@return components.PlacedTower?
function GameUI:find_placed_tower(tower)
  for _, el in ipairs(self.enemy_tower_children.children) do
    local placed_tower = PlacedTower.is(el)
    if placed_tower and placed_tower.tower.id == tower.id then
      return placed_tower
    end
  end
end

function GameUI:_update(_dt)
  self:_update_z_indexing()

  -- Show/hide next wave preview based on lifecycle
  if self.next_wave_preview then
    self.next_wave_preview:set_hidden(
      GAME.lifecycle ~= RoundLifecycle.PLAYER_TURN
        and GAME.lifecycle ~= RoundLifecycle.PLAYER_PREP
    )
  end

  local lifecycle = GAME.lifecycle
  if lifecycle == RoundLifecycle.PLAYER_TURN then
    -- Show the play button and discard button, not a huge fan of this though
    -- btw :) need to think of whether this can be a function or something else
    self:set_interactable(true)
    self.play_button:set_hidden(false)
    self.play_button:set_interactable(true)
    self.time_multiplier_button_toggle:set_hidden(true)
    self.time_multiplier_button:set_hidden(true)
    self.time_multiplier_button:set_interactable(false)

    -- Show discard all button only when we have exactly 1 discard left
    self.discard_all_button:set_hidden(State.player.discards ~= 1)
    self.discard_all_button:set_interactable(State.player.discards == 1)
  else
    -- Hide the play button and discard button
    self:set_interactable(false)
    self.play_button:set_hidden(true)
    self.time_multiplier_button_toggle:set_hidden(false)
    self.time_multiplier_button:set_hidden(false)
    self.time_multiplier_button:set_interactable(true)

    -- Hide discard all button during enemy turn
    self.discard_all_button:set_hidden(true)
  end
end

function GameUI:_update_z_indexing()
  local children = {}
  table.list_extend(children, self.enemy_tower_children.children)
  for _, el in ipairs(children) do
    el = el --[[@as Element]]

    if EnemySpawned.is(el) or PlacedTower.is(el) then
      --check to see if element is not in focus, allows us to interact with
      --focus elements

      el = el --[[@as components.PlacedTower| components.EnemySpawned]]

      if not el:is_focused() then
        -- local pos = el:get_pos()
        el.z = Z.GAME_UI + el.cell.row + 1
      end
    end
  end
end

function GameUI:_render() end

-- align elements along the y axis
-- @param alignment string "left" | "center" | "right"
-- @param size number
function GameUI:_get_y_position(alignment, size)
  if alignment == "top" then
    return size
  elseif alignment == "center" then
    return size / 2 -- TODO check how we're centering elsewhere
  elseif alignment == "bottom" then
    return Config.window_size.height - size
  end
end

-- align elements along the x axis
-- @param alignment string "left" | "center" | "right"
-- @param size number
function GameUI:_get_x_position(alignment, size)
  if alignment == "left" then
    return size
  elseif alignment == "center" then
    return Config.window_size.width / 2
  elseif alignment == "right" then
    return Config.window_size.width - size
  end
end

function GameUI:_setup_current_wave_indicator()
  self.current_wave_indicator = CurrentWaveIndicator.new {}
  self.current_wave_indicator.z = Z.TOOLTIP -- Same z-level as tooltips
  self:append_child(self.current_wave_indicator)
end

function GameUI:_setup_next_wave_preview()
  -- Use centralized UI config values
  local preview_config = Config.ui.next_wave_preview
  local button_config = Config.ui.time_multiplier_button

  -- Fallback to right edge with padding (accounting for button width)
  local horizontal_pos = self:_get_x_position(
    "right",
    Config.ui.next_wave_preview.width -- provide current element width
  ) - Config.ui.next_wave_preview.padding

  self.next_wave_preview = NextWavePreview.new {
    box = Box.new(
      Position.new(
        horizontal_pos,
        self:_get_y_position("top", Config.ui.next_wave_preview.padding)
      ),
      preview_config.width,
      preview_config.height
    ),
  }

  self.next_wave_preview.z = Z.TOOLTIP -- Same as tooltips
  self:append_child(self.next_wave_preview)
end

function GameUI:_setup_path_wave_previews()
  self.path_wave_previews = {}

  -- Get all paths from the current level
  local level = State.levels:get_current_level()
  if not level or not level.paths then
    return
  end

  -- Create a preview for each path
  for path_id, path in pairs(level.paths) do
    if path.cells and #path.cells > 0 then
      -- Get the first cell of the path (spawn point)
      local spawn_cell = path.cells[1]
      local spawn_position = Position.from_cell(spawn_cell)

      -- Create a small box for the preview (compact size)
      local preview_width = 150
      local preview_height = 200
      local preview_box = Box.new(spawn_position, preview_width, preview_height)

      -- Use PlaceBox to intelligently position it
      local positioned_box, _ = PlaceBox.position(
        preview_box,
        Box.new(spawn_position, 1, 1), -- Anchor point at spawn position
        {
          padding = PlaceBox.DEFAULT_PADDING,
          priority = { "right", "bottom", "left", "top" },
        }
      )

      -- Create the path wave preview
      local path_preview = PathWavePreview.new {
        box = positioned_box,
        path_id = path_id,
      }

      path_preview.z = Z.TOOLTIP -- Same as other previews
      self:append_child(path_preview)

      -- Store it for cleanup later
      self.path_wave_previews[path_id] = path_preview
    end
  end
end

function GameUI:_template_pile(name, cards, icon, z)
  -- Switch-case logic for pile positions based on name
  local position_map = {
    ["discard"] = Config.ui.deck.discard,
    ["exhausted"] = Config.ui.deck.exhausted,
    ["draw"] = Config.ui.deck.draw,
  }

  local pos = position_map[name]
  if not pos then
    error("Unknown pile name: " .. tostring(name))
  end

  return PileElement.new {
    name = name,
    cards = cards,
    box = Box.new(pos, Config.ui.deck.width, Config.ui.deck.height),
    icon = icon,
  }
end

function GameUI:_setup_buttons()
  self.play_button = ButtonElement.new {
    box = Box.new(
      Position.new(
        Config.window_size.width - 260,
        Config.window_size.height - 92
      ),
      219,
      60
    ),
    label = "Start Round",
    z = Z.DECK_BUTTON,
    on_click = function()
      local mode = State:get_mode() --[[@as vibes.GameMode]]
      mode.lifecycle = RoundLifecycle.ENEMIES_SPAWN_START
    end,
  }

  local deck_chip = Chip.new {
    position = Position.new(
      Config.ui.deck.draw.x,
      Config.window_size.height - 65 * 3
    ),
    icon_type = IconType.DECK,
    value = function() return tostring(#State.deck.draw_pile) end,
    on_click = function()
      ActionQueue:add(
        ViewPileAction.new { cards = State.deck.draw_pile, name = "Draw Pile" }
      )
    end,
  }

  local exhausted_chip = Chip.new {
    position = Position.new(350, Config.window_size.height - 67 * 2),
    icon_type = IconType.DECKEXHAUST,
    value = function() return tostring(#State.deck.exhausted_pile) end,
    on_click = function()
      ActionQueue:add(ViewPileAction.new {
        cards = State.deck.exhausted_pile,
        name = "Exhausted Pile",
      })
    end,
  }

  local discard_chip = Chip.new {
    position = Position.new(350, Config.window_size.height - 75),
    icon_type = IconType.DECKDISCARD,
    value = function() return tostring(#State.deck.discard_pile) end,
    on_click = function()
      ActionQueue:add(ViewPileAction.new {
        cards = State.deck.discard_pile,
        name = "Discard Pile",
      })
    end,
  }

  self:append_child(deck_chip)
  self:append_child(discard_chip)
  self:append_child(exhausted_chip)

  self:append_child(self.play_button)
end

function GameUI:_setup_time_multiplier_button()
  local SpeedToggleButton = require "ui.elements.speed-toggle-button"
  local SpeedButton = require "ui.elements.speed-button"

  self.time_multiplier_button_toggle = SpeedToggleButton.new {
    position = Position.new(
      Config.window_size.width - 260,
      Config.window_size.height - 98
    ),
    callback = function(pause) end,
  }

  self.time_multiplier_button = SpeedButton.new {
    position = Position.new(
      Config.window_size.width - 260 + 65,
      Config.window_size.height - 98
    ),
  }

  self:append_child(self.time_multiplier_button)
  self:append_child(self.time_multiplier_button_toggle)
end

function GameUI:_setup_cards()
  -- self.get_reactive_list = function() return State.deck.hand end
  -- self.create_element_for_item = function(_, card, _)
  --   return self:_create_card_from_item(card)
  -- end

  local hand_height = Config.ui.card.new_height * 0.5
  local hand_padding = 0.15 * Config.window_size.width
  local start_of_hand =
    Position.new(240, Config.window_size.height - hand_height)

  local Hand = require "ui.components.hand"

  self.hand = Hand.new {
    box = Box.new(
      start_of_hand,
      Config.window_size.width - hand_padding * 2,
      hand_height
    ),
    cards = State.deck.hand,
    create_card = function(card) return self:_create_card_from_item(card) end,
  }
  self:append_child(self.hand)
end

function GameUI:_create_card_from_item(card)
  local GameCard = require "ui.components.card.game-card"
  return GameCard.new {
    card = card,
    box = Box.new(
      Position.new(0, 0),
      Config.ui.card.new_width * 2,
      Config.ui.card.new_height * 2
    ),
    on_drag_start = function(card_element)
      ---@cast card_element components.GameCardElement

      self:_start_dropzone_for_dragged_card(card_element)
      -- card_element:animate_style { opacity = 0.2, scale = 0.2 }
      -- card_element.targets.scale = 0.1
      -- local tower = card_element.card:get_tower_card()
      -- if not tower then
      --   error(card_element)
      -- end
      -- error (card_element)
      card_element._index = table.find(State.deck.hand, card_element.card)

      return UIAction.HANDLED
    end,

    on_use = function(card_element)
      ---@cast card_element components.GameCardElement

      local target = State:get_placed_tower_at_mouse()
      -- local TryPlayCard = require "vibes.action.try-play-card"

      table.remove_item(State.deck.hand, card_element.card)

      local passesed = self:try_play_card(card, target, card_element)

      if not passesed then
        if card_element._index then
          table.insert(State.deck.hand, card_element._index, card_element.card)
        else
          table.insert(State.deck.hand, card_element.card)
        end
        card_element:animate_style({ opacity = 1, scale = 0.5 }, {
          duration = 0.2,
        })
      else
        card_element:animate_style({ opacity = 0.5, scale = 0.1 }, {
          duration = 0.2,
        })
      end

      -- ActionQueue:add(TryPlayCard.new {
      --   card = card,
      --   target = target,
      --   on_success = function()
      --     card_element:animate_style({ opacity = 0.5, scale = 0.1 }, {
      --       duration = 0.2,
      --     })
      --   end,
      --   on_cancel = function()
      --     -- table.insert(State.deck.hand, card_element._index, card_element.card)
      --     if card_element._index then
      --       table.insert(
      --         State.deck.hand,
      --         card_element._index,
      --         card_element.card
      --       )
      --     else
      --       table.insert(State.deck.hand, card_element.card)
      --     end
      --
      --     card_element:animate_style({ opacity = 1, scale = 0.5 }, {
      --       duration = 0.2,
      --     })
      --   end,
      -- })
    end,

    ---@param card_element components.GameCardElement
    ---@param evt ui.components.UIMouseEvent
    on_drag_end = function(card_element, evt)
      print("Dragging End:", card_element.card, "from playing card")

      -- First check drop zones and let them handle it
      if self:_finish_dropzone_for_dragged_card(card_element) then
        return
      end

      -- If no drop zones were hit, but it's outside of our hand region,
      -- then we just want to try and play the card (it can be cancelled)
      if not self.hand:contains_absolute_x_y(State.mouse.x, State.mouse.y) then
        card_element:on_use()
        return
      end

      -- Otherwise, let's put the card back in our hand
      card_element:animate_style { opacity = 1, scale = 0.5, rotation = 0 }
      return UIAction.HANDLED
    end,

    on_focus = function() return UIAction.HANDLED end,
    on_blur = function() return UIAction.HANDLED end,
  }
end

---@param el components.GameCardElement
function GameUI:_start_dropzone_for_dragged_card(el)
  for _, child in ipairs(self.enemy_tower_children.children) do
    if PlacedTower.is(child) then
      ---@cast child components.PlacedTower
      child:dropzone_on_start(el)
    end
  end
end

function GameUI:_finish_dropzone_for_dragged_card(el)
  local found = false
  for _, child in ipairs(self.enemy_tower_children.children) do
    if PlacedTower.is(child) then
      ---@cast child components.PlacedTower

      if child:dropzone_is_hovering() then
        child:dropzone_on_drop(el)
        found = true
      end

      child:dropzone_on_finish(el)
    end
  end

  return found
end

function GameUI:_setup_energy_display()
  local EnergyDisplay = require "ui.components.energy-display"

  -- Create energy display at position (1455, 990) with reasonable size
  self.energy_display = EnergyDisplay.new { pos = Position.new(1457, 997) }

  self.energy_display.z = Z.TOOLTIP -- Same z-level as tooltips
  self:append_child(self.energy_display)
end

function GameUI:_setup_discard_all_button()
  self.discard_all_button = ButtonElement.new {
    box = Box.new(
      Position.new(Config.ui.deck.draw.x, Config.window_size.height - 65 * 4),
      108,
      48
    ),
    label = "Shuffle",
    z = Z.DECK_BUTTON,
    on_click = function()
      -- Discard entire hand and draw new one
      self.hand:discard_hand()
      State.player.discards = State.player.discards - 1
      State.deck:draw_hand()
    end,
  }
  -- Use a smaller font to fit in the compact button
  self.discard_all_button.font =
    love.graphics.newFont("assets/fonts/Ohrenstead.ttf", 16, "normal")

  self:append_child(self.discard_all_button)
end

---@param card vibes.Card
---@param target? Element
function GameUI:try_play_card(card, target, card_element)
  local energy_cost = State:get_modified_energy_cost(card)

  if State.player.energy < energy_cost then
    UI:create_user_message "Not enough energy"
    return false
  end

  local tower_card = card:get_tower_card()

  if tower_card then
    GAME.ui:set_interactable(false)

    UI.root:append_child(PendingTower.new {
      tower = tower_card.tower,
      previous_lifecycle = GAME.lifecycle,
      on_place = function(cell, previous_lifecycle)
        GAME.ui:set_interactable(true)
        if not tower_card.tower:can_place(cell) then
          return false
        end

        local success = State:play_tower_card {
          tower_card = tower_card,
          cell = cell,
        }

        if success then
          card_element:animate_style({ opacity = 0.5, scale = 0.1 }, {
            duration = 0.2,
            on_complete = function() EventBus:emit_card_played { card = card } end,
          })
        end

        GAME.lifecycle = previous_lifecycle

        return success
      end,
      on_cancel = function(previous_lifecycle)
        if card_element._index then
          table.insert(State.deck.hand, card_element._index, card_element.card)
        else
          table.insert(State.deck.hand, card_element.card)
        end

        card_element:animate_style({ opacity = 1, scale = 0.5 }, {
          duration = 0.2,
        })

        GAME.ui:set_interactable(true)
        GAME.lifecycle = previous_lifecycle
        return false
      end,
    })

    GAME.lifecycle = RoundLifecycle.PLACING_TOWER

    return true
  end

  if target then
    local tower_target = require("ui.components.tower.placed-tower").is(target)
    if tower_target then
      local enhancement = card:get_enhancement_card()
      if enhancement then
        if not tower_target then
          UI:create_user_message "You must select a tower to enhance"
          return false
        end
        if not State:play_enhancement_card(enhancement, tower_target) then
          return false
        end
        return true
      end
    end
  end

  local aura = card:get_aura_card()
  if aura then
    if not State:play_aura_card(card) then
      return false
    end
    return true
  end
  return false
end

-- function GameUI:_click()
-- TODO: right click should make the cards go unselected. i miss it so much
--   return UIAction.HANDLED
-- end

return GameUI
