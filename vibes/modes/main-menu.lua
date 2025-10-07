local ButtonElement = require "ui.elements.button"
local Container = require "ui.components.container"
local EnemyBat = require "vibes.enemy.enemy-bat"
local EnemyOrc = require "vibes.enemy.enemy-orc"
local EnemyOrcChief = require "vibes.enemy.enemy-orc-chief"
local EnemyOrca = require "vibes.enemy.enemy-boss-orca"
local EnemySnail = require "vibes.enemy.enemy-elite-snail"
local EnemyViewer = require "ui.components.enemy-viewer"
local EnemyWyvern = require "vibes.enemy.enemy-boss-wyvern"
local GameModes = require "vibes.enum.mode-name"
local Level = require "vibes.level"

---@class (exact) vibes.MainMenu : vibes.BaseMode
---@field primary_theme_instance vibes.SoundInstance?
---@field world_map vibes.Texture
---@field level vibes.Level
---@field background_enemies vibes.Enemy[]
---@field _buttons elements.Button[]
---@field ui Element
local main_menu = {}

function main_menu:enter()
  self.world_map = Asset.sprites.world_map
  self.level =
    Level.new { level_data_path = "assets/level-json/3_level_3.json" }
  self.primary_theme_instance = SoundManager:play_primary_theme()

  -- Create background enemies for decoration
  self.background_enemies = {}
  self:create_background_enemies_immediately()

  self.ui = Container.new { box = Box.fullscreen() }
  UI.root:append_child(self.ui)

  local button_height = 80
  local button_width = 200
  local button_spacing = 30

  -- Layout: Large Play button on top, 3 viewers below, Settings and Credits in bottom right
  local play_button_width = button_width * 3 + button_spacing * 2
  local total_width = play_button_width
  local start_x = (Config.window_size.width - total_width) / 2
  local center_y = Config.window_size.height / 2
  local top_row_y = center_y - 100
  local viewer_row_y = center_y + 10

  -- Top row: Large Play button
  local play_btn = ButtonElement.new {
    on_click = function() State.mode = GameModes.CHARACTER_SELECTION end,
    label = "Play Game",
    interactable = true,
    box = Box.from(start_x, top_row_y, play_button_width, button_height),
    z = Z.MAX,
  }

  -- Viewer row: Three viewer buttons
  local collection_btn = ButtonElement.new {
    on_click = function() State.mode = GameModes.CARD_COLLECTION end,
    label = "Card Collection",
    interactable = true,
    box = Box.from(start_x, viewer_row_y, button_width, button_height),
  }
  collection_btn.z = Z.MAX

  local enemy_viewer_btn = ButtonElement.new {
    on_click = function()
      print "[DEBUG] MainMenu - Enemy Viewer button clicked"
      local viewer = EnemyViewer.new()
      print "[DEBUG] MainMenu - Enemy Viewer created, adding to UI.root"
      UI.root:append_child(viewer)
    end,
    label = "Enemy Viewer",
    interactable = true,
    box = Box.from(
      start_x + button_width + button_spacing,
      viewer_row_y,
      button_width,
      button_height
    ),
  }
  enemy_viewer_btn.z = Z.MAX

  local gear_btn = ButtonElement.new {
    on_click = function() State.mode = GameModes.GEAR_MENU end,
    label = "Gear Collection",
    interactable = true,
    box = Box.from(
      start_x + (button_width + button_spacing) * 2,
      viewer_row_y,
      button_width,
      button_height
    ),
  }
  gear_btn.z = Z.MAX

  -- Bottom right corner buttons
  local settings_btn = ButtonElement.new {
    on_click = function()
      local PauseAction = require "vibes.action.pause"
      if #ActionQueue.items == 0 then
        State.is_paused = true
        ActionQueue:add(PauseAction.new {})
      end
    end,
    label = "Settings",
    interactable = true,
    box = Box.from(
      Config.window_size.width - (button_width * 2) - button_spacing - 50,
      Config.window_size.height - button_height - 50,
      button_width,
      button_height
    ),
  }
  settings_btn.z = Z.MAX

  local credit_btn = ButtonElement.new {
    on_click = function() State.mode = GameModes.CREDITS end,
    label = "Credits",
    interactable = true,
    box = Box.from(
      Config.window_size.width - button_width - 50,
      Config.window_size.height - button_height - 50,
      button_width,
      button_height
    ),
  }
  credit_btn.z = Z.MAX

  local layout = Layout.new {
    name = "MainMenu(Layout)",
    box = Box.new(
      Position.new(start_x, top_row_y),
      play_button_width,
      button_height * 2 + button_spacing
    ),
    els = {
      play_btn,
      Layout.row {
        box = Box.new(Position.zero(), play_button_width, button_height),
        els = { collection_btn, enemy_viewer_btn, gear_btn },
        flex = {
          align_items = "start",
          direction = "row",
          justify_content = "start",
          gap = button_spacing,
        },
        animation_duration = 0,
      },
    },
    flex = {
      align_items = "start",
      direction = "column",
      justify_content = "start",
      gap = button_spacing,
    },
    animation_duration = 0,
  }

  self.ui:append_child(layout)
  self.ui:append_child(settings_btn)
  self.ui:append_child(credit_btn)

  -- Default focus: Play
  self._buttons = {
    play_btn,
    collection_btn,
    enemy_viewer_btn,
    gear_btn,
    settings_btn,
    credit_btn,
  }

  UI:focus_element(play_btn)
end

function main_menu:create_background_enemies_immediately()
  -- Create enemies of all types: bats, orcs, wyverns, snails, and orcas
  local enemy_types = {
    { class = EnemyBat, count = math.random(2, 4), spawn_delay = 8.0 },
    { class = EnemyOrc, count = math.random(2, 3), spawn_delay = 12.0 },
    { class = EnemyOrcChief, count = math.random(1, 2), spawn_delay = 15.0 },
    { class = EnemyWyvern, count = math.random(1, 2), spawn_delay = 20.0 },
    { class = EnemySnail, count = math.random(1, 3), spawn_delay = 18.0 },
    { class = EnemyOrca, count = math.random(1, 2), spawn_delay = 22.0 },
  }

  -- Get all available paths
  local paths_list = {}
  for _, path in pairs(self.level.paths) do
    table.insert(paths_list, path)
  end

  local total_enemies = 0
  for _, enemy_type_info in ipairs(enemy_types) do
    total_enemies = total_enemies + enemy_type_info.count
  end

  local enemy_index = 0
  for _, enemy_type_info in ipairs(enemy_types) do
    local enemy_class = enemy_type_info.class
    local count = enemy_type_info.count
    local spawn_delay = enemy_type_info.spawn_delay

    for i = 1, count do
      enemy_index = enemy_index + 1

      -- Choose a random path
      local random_path = paths_list[math.random(#paths_list)]

      if random_path and random_path.cells and random_path.cells[1] then
        -- Create enemy and spawn it at the start of the path
        local enemy = enemy_class.spawn(enemy_class, {
          path = random_path,
          enemy_level = 1,
          health = enemy_class._properties.health,
        })

        -- Position enemy at the start of the path, but offset far to the left based on spawn delay
        local start_cell = random_path.cells[1]
        local base_position = Position.from_cell(start_cell)

        -- Position enemies far to the left based on their intended spawn delay
        -- Use a large offset multiplier to spread them out significantly
        local offset_x = -(enemy_index * spawn_delay * 50)
          - (math.random() * 500)
        enemy.position =
          Position.new(base_position.x + offset_x, base_position.y)
        enemy.pathing_state.path_index = 1
        enemy.pathing_state.percent_complete = 0

        table.insert(self.background_enemies, enemy)
      end
    end
  end

  print(
    string.format(
      "Created %d background enemies across %d paths: %d bats, %d orcs, %d chiefs, %d wyverns, %d snails, %d orcas",
      total_enemies,
      #paths_list,
      enemy_types[1].count,
      enemy_types[2].count,
      enemy_types[3].count,
      enemy_types[4].count,
      enemy_types[5].count,
      enemy_types[6].count
    )
  )
end

function main_menu:exit()
  if self.primary_theme_instance then
    self.primary_theme_instance.sound:stop()
  end
end

function main_menu:update(dt)
  -- Update background enemies - they all move immediately
  for _, enemy in ipairs(self.background_enemies) do
    enemy:update(dt)

    -- Reset enemies that have completed their path, positioning them far left to come back around
    if enemy.pathing_state.percent_complete >= 1 then
      if
        enemy.pathing_state.path
        and enemy.pathing_state.path.cells
        and enemy.pathing_state.path.cells[1]
      then
        local start_cell = enemy.pathing_state.path.cells[1]
        local base_position = Position.from_cell(start_cell)

        -- Position far to the left with some randomness for the next cycle
        local offset_x = -(math.random(100, 200) * 50)
        enemy.position =
          Position.new(base_position.x + offset_x, base_position.y)
        enemy.pathing_state.path_index = 1
        enemy.pathing_state.percent_complete = 0
      end
    end
  end
end

function main_menu:draw()
  -- Draw the first level as background
  love.graphics.push()
  love.graphics.translate(
    (Config.window_size.width - Config.grid.grid_width * Config.grid.cell_size)
      / 2,
    (
      Config.window_size.height
      - Config.grid.grid_height * Config.grid.cell_size
    ) / 2
  )
  self.level:draw()

  -- Draw background enemies
  for _, enemy in ipairs(self.background_enemies) do
    enemy:draw()
  end

  love.graphics.pop()

  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(Asset.ui.title_screen, 0, 0, 0, 2, 2)
end

---@param key string
function main_menu:keypressed(key)
  if key == "left" or key == "right" or key == "up" or key == "down" then
    local delta = (key == "right" or key == "down") and 1 or -1
    UI:cycle_focus(self._buttons, delta)
    return true
  elseif key == "return" or key == "kpenter" then
    if UI.state.selected then
      UI:activate_element(UI.state.selected)
      return true
    end
  end
end

return require("vibes.base-mode").wrap(main_menu)
