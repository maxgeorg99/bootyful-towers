local ButtonElement = require "ui.elements.button"
local Container = require "ui.components.container"
local Dialog = require "ui.components.dialog"
local Label = require "ui.components.label"

local Enemy = require "vibes.enemy.base"
local SpawnEntry = require "vibes.enemy.spawn-entry"

local EnemyViewer = class("ui.components.EnemyViewer", { super = Element })

--- @class (exact) ui.components.EnemyViewer : Element
--- @field new fun(): ui.components.EnemyViewer
--- @field init fun(self: ui.components.EnemyViewer)
--- @field left_panel Container
--- @field right_panel Container
--- @field enemy_list_container Container
--- @field selected_enemy vibes.Enemy?
--- @field enemy_list_items elements.Button[]
--- @field enemy_classes vibes.Enemy[]
--- @field enemy_animation vibes.SpriteAnimation?
--- @field anim_position vibes.Position?
--- @field anim_scale number?
--- @field enemy_name string
--- @field spawned_enemy vibes.Enemy? The actual enemy instance for preview
--- @field preview_path vibes.Path? Simple path for the enemy preview to walk on
--- @field main_menu_ui Element? Reference to the main menu UI to hide/show

function EnemyViewer:init()
  -- Find and hide the main menu UI if we're in main menu mode
  self:setup_main_menu_ui()

  -- Initialize with fullscreen box but no dialog/overlay
  Element.init(self, Box.fullscreen())

  -- Ensure enemy viewer has high z-index to be above game elements
  self.z = Z.GAME_UI + 1000

  -- Center the panels properly
  local center_x = Config.window_size.width / 2
  local center_y = Config.window_size.height / 2

  -- Create left panel (enemy list) - centered
  local left_panel_x = 50
  local left_panel_y = center_y - 300
  self.left_panel = Container.new {
    box = Box.new(Position.new(left_panel_x, left_panel_y), 300, 600),
  }
  self.left_panel.z = math.max(self.left_panel.z, self.z + 1)
  self:append_child(self.left_panel)

  -- Create right panel (enemy details) - centered
  local right_panel_width = Config.window_size.width - 500
  local right_panel_height = 600
  local right_panel_x = center_x + 50
  local right_panel_y = center_y - 300

  self.right_panel = Container.new {
    box = Box.new(
      Position.new(right_panel_x, right_panel_y),
      right_panel_width,
      right_panel_height
    ),
  }
  self.right_panel.z = math.max(self.right_panel.z, self.z + 2)
  self:append_child(self.right_panel)

  -- Create enemy list container (scrollable area) - centered within left panel
  self.enemy_list_container = Container.new {
    box = Box.new(Position.new(0, 60), 300, 540),
  }
  self.enemy_list_container.z =
    math.max(self.enemy_list_container.z, self.left_panel.z + 1)
  self.left_panel:append_child(self.enemy_list_container)

  -- Title for left panel
  local title_label =
    Label.new(Asset.fonts.default_18, "Enemies", { 1, 1, 1 }, "center")
  title_label.z = math.max(title_label.z, self.left_panel.z + 2)
  self.left_panel:append_child(title_label)

  -- Get all enemy classes
  self.enemy_classes = SpawnEntry.enemy_classes

  -- Create list items
  self.enemy_list_items = {}
  self:create_enemy_list()

  -- Add close button - centered at top right
  local close_button = ButtonElement.new {
    box = Box.new(Position.new(Config.window_size.width - 200, 50), 150, 40),
    label = "Close",
    on_click = function() self:close_enemy_viewer() end,
  }
  close_button.z = math.max(close_button.z, self.z + 100)
  self:append_child(close_button)
end

function EnemyViewer:create_enemy_list()
  -- Create a layout for the enemy list items
  local enemy_list_layout = Layout.col {
    box = Box.new(Position.new(0, 60), 280, Config.window_size.height - 260),
    flex = {
      direction = "column",
      justify_content = "start",
      align_items = "stretch",
      gap = 5,
    },
  }

  for i, enemy_class in ipairs(self.enemy_classes) do
    local enemy_name = string.match(enemy_class._type, "Enemy(%w+)$")
      or "Unknown"

    local button = ButtonElement.new {
      box = Box.new(Position.new(0, 0), 280, 50),
      label = enemy_name,
      on_click = function() self:select_enemy(enemy_class) end,
    }
    button.z = math.max(button.z, enemy_list_layout.z + 1)

    enemy_list_layout:append_child(button)
    table.insert(self.enemy_list_items, button)

    -- Select first enemy by default
    if i == 1 then
      self:select_enemy(enemy_class)
    end
  end

  self.enemy_list_container:append_child(enemy_list_layout)
end

--- Select an enemy and display its details
--- @param enemy_class vibes.Enemy
function EnemyViewer:select_enemy(enemy_class)
  self.selected_enemy = enemy_class
  self.enemy_name = string.match(enemy_class._type, "Enemy(%w+)$") or "Unknown"

  -- Create preview path for the enemy to walk on
  self:create_preview_path()

  -- Create spawned enemy instance for preview
  self:create_spawned_enemy(enemy_class)

  -- Update right panel with enemy details
  self:update_enemy_details()
end

function EnemyViewer:update_enemy_details()
  -- Clear existing children from right panel
  self.right_panel:remove_all_children()

  if not self.selected_enemy then
    return
  end

  local props = self.selected_enemy._properties

  -- Ensure right panel has correct z-index
  self.right_panel.z = math.max(self.right_panel.z, self.z + 10)

  -- Create layout for the stats section
  local stats_layout = Layout.col {
    box = Box.new(
      Position.new(20, 20),
      self.right_panel:get_width() - 40,
      self.right_panel:get_height() - 40
    ),
    flex = {
      direction = "column",
      justify_content = "start",
      align_items = "stretch",
      gap = 10,
    },
  }
  stats_layout.z = math.max(stats_layout.z, self.right_panel.z + 1)
  self.right_panel:append_child(stats_layout)

  -- Enemy name title
  local name_label =
    Label.new(Asset.fonts.default_20, self.enemy_name, { 1, 1, 1 }, "left")
  name_label.z = math.max(name_label.z, stats_layout.z + 1)
  stats_layout:append_child(name_label)

  -- Enemy stats
  local stats = {
    { "Health", tostring(props.health or "N/A") },
    { "Speed", tostring(props.speed or "N/A") },
    { "Gold Reward", tostring(props.gold_reward or "N/A") },
    { "XP Reward", tostring(props.xp_reward or "N/A") },
    { "Enemy Type", tostring(props.enemy_type or "N/A") },
  }

  for i, stat in ipairs(stats) do
    local stat_label = Label.new(
      Asset.fonts.default_18,
      stat[1] .. ": " .. stat[2],
      { 0.8, 0.8, 0.8 },
      "left"
    )
    stat_label.z = math.max(stat_label.z, stats_layout.z + 1 + i)
    stats_layout:append_child(stat_label)
  end

  -- Animation preview (if available)
  if props.animation then
    local anim_label = Label.new(
      Asset.fonts.default_18,
      "Animation Preview:",
      { 1, 1, 1 },
      "left"
    )
    anim_label.z = math.max(anim_label.z, stats_layout.z + 10)
    stats_layout:append_child(anim_label)

    -- Store animation for drawing
    self.enemy_animation = props.animation
    self.anim_position = Position.new(50, 300)
    self.anim_scale = 2
  end
end

--- Create a simple preview path for the enemy to walk on
function EnemyViewer:create_preview_path()
  -- Create a simple horizontal path in the right panel area
  local start_x = 420
  local start_y = Config.window_size.height - 200

  local cells = {
    Cell.new(
      math.floor(start_x / Config.grid.cell_size),
      math.floor(start_y / Config.grid.cell_size)
    ),
    Cell.new(
      math.floor((start_x + 100) / Config.grid.cell_size),
      math.floor(start_y / Config.grid.cell_size)
    ),
    Cell.new(
      math.floor((start_x + 200) / Config.grid.cell_size),
      math.floor(start_y / Config.grid.cell_size)
    ),
    Cell.new(
      math.floor((start_x + 300) / Config.grid.cell_size),
      math.floor(start_y / Config.grid.cell_size)
    ),
  }

  self.preview_path = Path.new {
    cells = cells,
    id = "enemy_preview_path",
  }
end

--- Create a spawned enemy instance for preview
--- @param enemy_class vibes.Enemy
function EnemyViewer:create_spawned_enemy(enemy_class)
  -- Clean up existing spawned enemy
  if self.spawned_enemy then
    self.spawned_enemy = nil
  end

  if not self.preview_path then
    return
  end

  -- Create enemy instance
  local enemy = Enemy.spawn(enemy_class, {
    path = self.preview_path,
    enemy_level = 1,
    health = enemy_class._properties.health,
  })

  -- Position the enemy at the start of the preview path
  enemy.position = Position.from_cell(self.preview_path.cells[1])

  self.spawned_enemy = enemy
end

--- Setup main menu UI reference and hide it if we're in main menu mode
function EnemyViewer:setup_main_menu_ui()
  -- Check if we're in main menu mode
  if State.mode == require("vibes.enum.mode-name").MAIN_MENU then
    -- Get the current mode instance (main menu)
    local main_menu = MODES[State.mode]
    if main_menu and main_menu.ui then
      self.main_menu_ui = main_menu.ui

      -- Hide the main menu UI by setting its opacity to 0
      -- We'll use a fade effect for better UX
      self.main_menu_ui:set_opacity(0)
    end
  end
end

--- Close the enemy viewer and restore main menu UI
function EnemyViewer:close_enemy_viewer()
  -- Restore main menu UI if it exists
  if self.main_menu_ui then
    self.main_menu_ui:set_opacity(1)
  end

  -- Remove the enemy viewer from UI root
  UI.root:remove_child(self)
end

function EnemyViewer:_render()
  -- Draw enemy animation if available
  if self.enemy_animation and self.anim_position then
    love.graphics.setColor(1, 1, 1)
    self.enemy_animation:draw(self.anim_position, self.anim_scale, false)
  end

  -- Draw spawned enemy instance if available
  if self.spawned_enemy then
    love.graphics.setColor(1, 1, 1)
    self.spawned_enemy:draw()
  end
end

function EnemyViewer:_update(dt)
  -- Update spawned enemy if available
  if self.spawned_enemy then
    self.spawned_enemy:update(dt)
  end

  -- Animation updates automatically based on time.gametime()
end

return EnemyViewer
