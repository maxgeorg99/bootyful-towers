local ButtonElement = require "ui.elements.button"
local Chip = require "ui.elements.chip"
local CurrentWaveIndicator = require "ui.components.wave.current-wave-indicator"
local GameModes = require "vibes.enum.mode-name"
local LowerThird = require "ui.components.lower-third"
local ReadOnlyThreeByThreeGear =
  require "ui.components.inventory.readonly-three-by-three-gear"
local TotalDamageDealtDisplay =
  require "ui.components.player.total-damage-display"
local UIRootElement = require "ui.components.ui-root-element"
local ViewPileAction = require "vibes.action.view-pile"

---@class vibes.MapMode : vibes.BaseMode
---@field animation_time number
local map_mode = {}

function map_mode:enter()
  -- Use the pre-loaded world map image from Asset.sprites
  self.world_map = Asset.sprites.world_map

  -- Initialize animation time
  self.animation_time = 0

  print "map_mode.enter"

  SoundManager:play_round_music()

  -- Create UI root element
  local ui = UIRootElement.new()

  -- Add lower third element
  local lower_third = LowerThird.new {
    z = Z.LOWER_THIRD,
  }
  ui:append_child(lower_third)

  -- Create start level button (centered)
  local start_level_button = ButtonElement.new {
    box = Box.from(
      Config.window_size.width / 2 - 190, -- Offset left to make room for shop button
      Config.window_size.height - 140,
      230, -- Width to prevent text overflow
      80 -- Height
    ),
    label = "Start Level " .. (State.levels.current_level_idx or 1),
    on_click = function()
      -- When starting a new level from the map screen,
      -- we need to make sure that returning_from_shop is NOT set
      -- unless we actually came from the shop
      if not State.returning_from_shop then
        -- If not already set, ensure we're not marked as returning from shop
        State.returning_from_shop = false

        -- Debug message to confirm we're starting a fresh level
        print(
          "Starting new map - towers should be reset, tower count:",
          #State.towers
        )
      else
        print(
          "Returning from shop to map to game - tower count:",
          #State.towers
        )
      end

      -- Start the level
      State.mode = GameModes.GAME
    end,
  }

  -- Create shop button (right next to start level button)
  local shop_button = ButtonElement.new {
    box = Box.from(
      Config.window_size.width / 2 + 50, -- Position right next to start level button
      Config.window_size.height - 140,
      150,
      80
    ),
    label = "Shop",
    on_click = function() State.mode = GameModes.SHOP end,
  }

  -- Store references to buttons
  self.shop_button = shop_button
  self.start_level_button = start_level_button

  -- Add buttons to UI
  ui:append_child(start_level_button)
  ui:append_child(shop_button)

  -- Add read-only gear display
  local gear_display = ReadOnlyThreeByThreeGear.new {
    z = Z.GEAR_DISPLAY,
  }
  ui:append_child(gear_display)

  -- Add deck chips (draw pile, discard pile, exhausted pile)
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

  ui:append_child(deck_chip)
  ui:append_child(discard_chip)
  ui:append_child(exhausted_chip)

  -- Add energy display
  local EnergyDisplay = require "ui.components.energy-display"
  local energy_display = EnergyDisplay.new { pos = Position.new(1457, 997) }
  energy_display.z = Z.TOOLTIP
  ui:append_child(energy_display)

  -- Add current wave indicator (shows 0 out of 8 on map screen)
  local wave_indicator = CurrentWaveIndicator.new {}
  wave_indicator.z = Z.TOOLTIP
  ui:append_child(wave_indicator)

  -- Add total damage dealt display
  local damage_display = TotalDamageDealtDisplay.new {}
  damage_display.z = Z.MAX
  ui:append_child(damage_display)

  -- Add UI to root
  UI.root:append_child(ui)
end

function map_mode:exit()
  print "map_mode.exit"
  SoundManager:stop_round_music()
end

function map_mode:update(dt)
  -- Update animation time for shader and breathing effects
  self.animation_time = self.animation_time + dt

  -- Update the map fadeout shader time
  Asset.shaders.map_fadeout:send { time = self.animation_time }
end

---@param key string
function map_mode:keypressed(key)
  if key == "return" or key == "kpenter" then
    print "[map] Enter pressed - starting level"
    if self.start_level_button and self.start_level_button._click then
      self.start_level_button:_click()
      return true
    end
  end
end

function map_mode:draw()
  -- This previously used love.graphics.getDimensions(), but that caused
  -- the map to be stretched to the window size instead of scaling to fit.
  local window_width = Config.window_size.width
  local window_height = Config.window_size.height

  -- Draw a black background
  love.graphics.clear(0, 0, 0)

  -- Apply shader to the world map
  love.graphics.setShader(Asset.shaders.map_fadeout.shader)

  -- slightly transparent for effect
  love.graphics.setColor(1, 1, 1, 0.6)
  local scale = math.max(
    window_width / self.world_map:getWidth(),
    window_height / self.world_map:getHeight()
  )

  local map_x = (window_width - self.world_map:getWidth() * scale) / 2
  local map_y = (window_height - self.world_map:getHeight() * scale) / 2

  love.graphics.draw(self.world_map, map_x, map_y, 0, scale, scale)

  -- Reset shader after drawing the map
  love.graphics.setShader()

  -- Draw title with shadow for better visibility
  love.graphics.setColor(0, 0, 0, 0.7)
  love.graphics.setFont(Asset.fonts.insignia_36)
  love.graphics.printf(
    "Level " .. State.levels.current_level_idx,
    2,
    Config.window_size.height * 0.05 + 2,
    Config.window_size.width,
    "center"
  )

  -- Draw title
  love.graphics.setColor(1, 1, 1)
  love.graphics.setFont(Asset.fonts.insignia_48)
  love.graphics.printf(
    "Level " .. State.levels.current_level_idx,
    0,
    Config.window_size.height * 0.05,
    Config.window_size.width,
    "center"
  )

  -- Calculate path display parameters with breathing animation
  local breath = math.sin(self.animation_time * 0.8) * 3
  local center_x = window_width / 2 + math.sin(self.animation_time * 0.3) * 2
  local center_y = window_height / 2 + math.cos(self.animation_time * 0.25) * 2
  local node_radius = 25 + breath * 0.3 -- Slightly larger nodes with breathing
  local node_spacing = 100
  local total_visible_nodes = 7 -- 3 previous, current, 3 future
  local start_x = center_x - (node_spacing * (total_visible_nodes - 1) / 2)
  local path_y = center_y

  -- Draw path lines first (behind nodes) with shadow effect for visibility
  -- Shadow
  love.graphics.setColor(0, 0, 0, 0.7)
  love.graphics.setLineWidth(6)
  love.graphics.line(
    start_x,
    path_y + 2,
    start_x + node_spacing * (total_visible_nodes - 1),
    path_y + 2
  )

  -- Main line
  love.graphics.setColor(0.8, 0.8, 0.8, 0.9)
  love.graphics.setLineWidth(4)
  love.graphics.line(
    start_x,
    path_y,
    start_x + node_spacing * (total_visible_nodes - 1),
    path_y
  )
  love.graphics.setLineWidth(1)

  -- Calculate which levels to show
  local start_level = math.max(1, State.levels.current_level_idx - 3)
  local end_level = start_level + total_visible_nodes - 1

  -- Draw nodes
  for i = 0, total_visible_nodes - 1 do
    local level = start_level + i
    -- Add slight wave motion to each node
    local wave_offset = math.sin(self.animation_time * 1.2 + i * 0.5) * 1.5
    local x = start_x + (i * node_spacing)
    local y = path_y + wave_offset

    -- Draw node shadow for better visibility
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.circle("fill", x + 2, y + 2, node_radius)

    -- Draw node
    if level == State.levels.current_level_idx then
      -- Current level (larger, gold with pulsing glow)
      local glow = 0.15 + math.sin(self.animation_time * 2.0) * 0.1
      love.graphics.setColor(1, 0.8, 0, 0.9 + glow)
      love.graphics.circle("fill", x, y, node_radius * 1.2)
      love.graphics.setColor(0, 0, 0, 0.8)
      love.graphics.setLineWidth(2)
      love.graphics.circle("line", x, y, node_radius * 1.2)
      love.graphics.setLineWidth(1)
    elseif level < State.levels.current_level_idx then
      -- Completed level (green)
      love.graphics.setColor(0, 0.8, 0, 0.9)
      love.graphics.circle("fill", x, y, node_radius)
      love.graphics.setColor(0, 0, 0, 0.8)
      love.graphics.setLineWidth(2)
      love.graphics.circle("line", x, y, node_radius)
      love.graphics.setLineWidth(1)
    else
      -- Future level (gray with slight transparency)
      love.graphics.setColor(0.3, 0.3, 0.4, 0.8)
      love.graphics.circle("fill", x, y, node_radius)
      love.graphics.setColor(0.6, 0.6, 0.7, 0.9)
      love.graphics.setLineWidth(2)
      love.graphics.circle("line", x, y, node_radius)
      love.graphics.setLineWidth(1)
    end

    -- Draw level number with shadow for better visibility
    -- Shadow
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.setFont(Asset.fonts.insignia_18) -- Slightly larger font
    if level == 10 then
      love.graphics.printf(
        "BOSS",
        x - node_radius + 2,
        y - 8 + 2,
        node_radius * 2,
        "center"
      )
    elseif level > 10 then
      love.graphics.printf(
        "∞",
        x - node_radius + 2,
        y - 8 + 2,
        node_radius * 2,
        "center"
      )
    else
      love.graphics.printf(
        tostring(level),
        x - node_radius + 2,
        y - 8 + 2,
        node_radius * 2,
        "center"
      )
    end

    -- Actual text
    love.graphics.setColor(1, 1, 1, 1)
    if level == 10 then
      love.graphics.printf(
        "BOSS",
        x - node_radius,
        y - 8,
        node_radius * 2,
        "center"
      )
    elseif level > 10 then
      love.graphics.printf(
        "∞",
        x - node_radius,
        y - 8,
        node_radius * 2,
        "center"
      )
    else
      love.graphics.printf(
        tostring(level),
        x - node_radius,
        y - 8,
        node_radius * 2,
        "center"
      )
    end
  end
end

-- (Removed duplicate keypressed; handled above to call start_level_button.on_click)

return require("vibes.base-mode").wrap(map_mode)
