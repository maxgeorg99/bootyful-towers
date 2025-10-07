local ButtonElement = require "ui.elements.button"
local Container = require "ui.components.container"
local GameModes = require "vibes.enum.mode-name"
local GearState = require "gear.state"
local SimpleGear = require "ui.components.simple-gear"
local Text = require "ui.components.text"

---@class vibes.GearMenu : vibes.BaseMode
---@field world_map vibes.Texture
---@field ui Element
---@field gear_dialog Container
---@field gear_buttons elements.Button[]
---@field current_category GearKind?
---@field filter_buttons elements.Button[]
---@field current_page number
---@field items_per_page number
---@field total_pages number
---@field gear_list gear.Gear[]
local gear_menu = {}

function gear_menu:enter()
  -- Load world map for background (same as main menu)
  self.world_map = Asset.sprites.world_map

  self.ui = Container.new { box = Box.fullscreen() }
  UI.root:append_child(self.ui)

  -- Initialize pagination
  self.current_page = 1
  self.items_per_page = 8
  self.total_pages = 1
  self.gear_list = {}

  -- Add title (matching main menu styling and position)
  local title = Text.new {
    function() return "GEAR COLLECTION" end,
    text_align = "center",
    color = Colors.white:get(), -- matching main menu white color
    font = Asset.fonts.insignia_48,
    box = Box.new(
      Position.new(0, Config.window_size.height * 0.1), -- exactly matching main menu position
      Config.window_size.width,
      60
    ),
  }
  self.ui:append_child(title)

  -- Add back button (top left corner, matching gear-selection.lua cancel button)
  local PADDING = 80 -- matching gear-selection.lua
  local back_button = ButtonElement.new {
    box = Box.new(Position.new(PADDING, PADDING), 250, 65),
    label = "Back to Main Menu",
    on_click = function() State.mode = GameModes.MAIN_MENU end,
  }
  self.ui:append_child(back_button)

  -- Add category filter buttons
  self:create_category_filters()

  -- Add gear display area
  self:create_gear_display()
end

function gear_menu:exit()
  -- Clean up UI
  if self.ui then
    self.ui:remove_from_parent()
  end
end

function gear_menu:draw()
  -- Draw background (same as main menu)
  love.graphics.setColor(0.1, 0.1, 0.2)
  love.graphics.rectangle(
    "fill",
    0,
    0,
    Config.window_size.width,
    Config.window_size.height
  )

  -- Draw world map to cover the entire screen (same as main menu)
  love.graphics.setColor(1, 1, 1, 1)
  local map = self.world_map

  -- Calculate scale to cover the entire screen
  local scale_x = Config.window_size.width / map:getWidth()
  local scale_y = Config.window_size.height / map:getHeight()
  local scale = math.max(scale_x, scale_y) -- Use max to ensure full coverage

  -- Center the map on screen
  local map_x = (Config.window_size.width - map:getWidth() * scale) / 2
  local map_y = (Config.window_size.height - map:getHeight() * scale) / 2

  love.graphics.draw(map, map_x, map_y, 0, scale, scale)

  -- Reset color to white for UI elements
  love.graphics.setColor(1, 1, 1, 1)
end

function gear_menu:update(_)
  -- No update needed for static menu
end

function gear_menu:create_category_filters()
  local filter_y = Config.window_size.height * 0.18 -- move up closer to title
  local filter_width = 120
  local filter_height = 40
  local filter_spacing = 10

  -- Calculate total width and center the filter buttons
  local total_buttons = 8 -- All + 7 categories
  local total_width = total_buttons * filter_width
    + (total_buttons - 1) * filter_spacing
  local start_x = (Config.window_size.width - total_width) / 2

  self.filter_buttons = {}

  -- All gear button
  local all_button = ButtonElement.new {
    box = Box.from(start_x, filter_y, filter_width, filter_height),
    label = "All",
    on_click = function() self:filter_by_category(nil) end,
  }
  self.ui:append_child(all_button)
  table.insert(self.filter_buttons, all_button)

  -- Category buttons
  local categories = {
    { kind = GearKind.HAT, name = "Hats" },
    { kind = GearKind.SHIRT, name = "Shirts" },
    { kind = GearKind.PANTS, name = "Pants" },
    { kind = GearKind.SHOES, name = "Shoes" },
    { kind = GearKind.NECKLACE, name = "Necklaces" },
    { kind = GearKind.RING, name = "Rings" },
    { kind = GearKind.TOOL, name = "Tools" },
  }

  for i, category in ipairs(categories) do
    local x = start_x + (filter_width + filter_spacing) * i
    local button = ButtonElement.new {
      box = Box.from(x, filter_y, filter_width, filter_height),
      label = category.name,
      on_click = function() self:filter_by_category(category.kind) end,
    }

    ---@diagnostic disable-next-line
    button._category_kind = category.kind
    self.ui:append_child(button)
    table.insert(self.filter_buttons, button)
  end

  -- Set default selection
  self.current_category = nil
  self:update_filter_buttons()
end

function gear_menu:create_gear_display()
  -- Calculate centered position for gear display area
  local area_width = Config.window_size.width - 200
  local area_height = Config.window_size.height - 350
  local area_x = (Config.window_size.width - area_width) / 2
  local area_y = (Config.window_size.height - area_height) / 2

  -- Create scrollable area for gear items (centered)
  local gear_area = Container.new {
    box = Box.new(Position.new(area_x, area_y), area_width, area_height),
  }
  self.ui:append_child(gear_area)

  self.gear_area = gear_area
  self.gear_buttons = {}

  -- Populate with all gear initially
  self:display_gear()
end

function gear_menu:filter_by_category(category)
  self.current_category = category
  self.current_page = 1 -- Reset to first page when filtering
  self:update_filter_buttons()
  self:display_gear()
end

function gear_menu:update_filter_buttons()
  for i, button in ipairs(self.filter_buttons) do
    local is_selected = (i == 1 and self.current_category == nil)
      or (
        i > 1
        ---@diagnostic disable-next-line
        and self.current_category == self.filter_buttons[i]._category_kind
      )

    -- if is_selected then
    --   button.default_color = Colors.gold
    --   button.hover_color = Colors.dark_gold
    -- else
    --   button.default_color = Colors.burgundy
    --   button.hover_color = Colors.dark_burgundy
    -- end
  end
end

function gear_menu:display_gear()
  -- Clear existing gear display
  if self.gear_area then
    self.gear_area:remove_all_children()
  end

  self.gear_buttons = {}

  -- Get filtered gear
  local gear_list = {}
  for gear_name, gear in pairs(GearState) do
    if not self.current_category or gear.kind == self.current_category then
      table.insert(gear_list, gear)
    end
  end

  -- Sort gear by rarity and name
  table.sort(gear_list, function(a, b)
    if a.rarity ~= b.rarity then
      return a.rarity > b.rarity -- Higher rarity first
    end
    return a.name < b.name
  end)

  -- Store the full gear list for pagination
  self.gear_list = gear_list
  self.total_pages = math.ceil(#gear_list / self.items_per_page)

  -- Calculate which items to show on current page
  local start_index = (self.current_page - 1) * self.items_per_page + 1
  local end_index = math.min(start_index + self.items_per_page - 1, #gear_list)

  -- Display gear in grid (4 items per row, 2 rows per page)
  local items_per_row = 4
  local item_width = 160
  local item_height = 200
  local item_spacing = 0

  -- Calculate centered position for gear grid within the gear area
  local total_grid_width = items_per_row * item_width
    + (items_per_row - 1) * item_spacing
  local total_grid_height = 2 * item_height + item_spacing -- 2 rows max
  local area_width = Config.window_size.width - 200
  local area_height = Config.window_size.height - 350

  local start_x = (area_width - total_grid_width) / 2
  local start_y = (area_height - total_grid_height) / 2

  for i = start_index, end_index do
    local gear = gear_list[i]
    if gear then
      local page_index = i - start_index + 1
      local row = math.floor((page_index - 1) / items_per_row)
      local col = (page_index - 1) % items_per_row

      local x = start_x + col * (item_width + item_spacing)
      local y = start_y + row * (item_height + item_spacing)

      self:create_gear_item(gear, x, y, item_width, item_height, end_index, i)
    end
  end

  -- Add pagination controls
  self:create_pagination_controls()
end

function gear_menu:create_gear_item(
  gear,
  x,
  y,
  width,
  height,
  end_index,
  current_index
)
  local ScaledImage = require "ui.components.scaled-img"
  local Layout = require "ui.components.layout"

  local gear_container = Container.new {
    box = Box.new(Position.new(x, y), width, height),
  }
  self.gear_area:append_child(gear_container)

  -- Get gear kind color (matching gear-selection.lua style)
  local kind_colors = {
    [GearKind.HAT] = Colors.purple:get(),
    [GearKind.SHIRT] = Colors.blue:get(),
    [GearKind.PANTS] = Colors.green:get(),
    [GearKind.SHOES] = Colors.brown:get(),
    [GearKind.NECKLACE] = Colors.yellow:get(),
    [GearKind.RING] = Colors.orange:get(),
    [GearKind.TOOL] = Colors.red:get(),
  }
  local gear_color = kind_colors[gear.kind] or Colors.gray:get()

  -- Create layout matching gear-selection.lua structure
  local layout = Layout.new {
    -- z = (end_index - current_index) * 1000,
    name = "GearItem",
    animation_duration = 0,
    box = Box.new(Position.zero(), width, height),
    els = {
      -- Gear icon/texture area (60% of height)
      Layout.new {

        name = "GearIcon",
        animation_duration = 0,
        box = Box.new(Position.zero(), width, height * 0.6),
        els = {
          SimpleGear.new {
            box = Box.new(Position.zero(), width, height * 0.6),
            gear = gear,
          },
        },
        flex = {
          direction = "column",
          justify_content = "center",
          align_items = "center",
        },
      },
      -- Gear info area (40% of height)
      Layout.new {
        name = "GearInfo",
        animation_duration = 0,
        box = Box.new(Position.zero(), width, height * 0.4),
        els = {
          Text.new {
            function() return gear.name end,
            text_align = "center",
            color = Colors.white:get(),
            font = Asset.fonts.typography.paragraph_md,
            box = Box.new(Position.zero(), width, 25),
          },
          Text.new {
            function() return string.upper(gear.kind) end,
            text_align = "center",
            color = gear_color,
            font = Asset.fonts.typography.paragraph_sm,
            box = Box.new(Position.zero(), width, 20),
          },
        },
        flex = {
          direction = "column",
          justify_content = "start",
          align_items = "center",
          gap = 5,
        },
      },
    },
    flex = {
      direction = "column",
      justify_content = "start",
      align_items = "center",
    },
  }

  gear_container:append_child(layout)
end

function gear_menu:create_pagination_controls()
  if self.total_pages <= 1 then
    return -- Don't show pagination if there's only one page
  end

  -- Clear existing pagination controls
  if self._pagination_controls then
    for _, control in ipairs(self._pagination_controls) do
      if control.remove_from_parent then
        control:remove_from_parent()
      end
    end
  end
  self._pagination_controls = {}

  local pagination_y = Config.window_size.height * 0.75 -- position at bottom of gear area
  local button_width = 60
  local button_height = 60
  local button_spacing = 15
  local center_x = Config.window_size.width / 2
  local start_x = center_x - (button_width * 2 + button_spacing) / 2 - 65

  -- Pagination buttons matching gear-selection.lua style
  local prev_button = ButtonElement.new {
    box = Box.new(
      Position.new(start_x, pagination_y),
      button_width,
      button_height
    ),
    label = "<",
    on_click = function()
      if self.current_page > 1 then
        self.current_page = self.current_page - 1
        self:display_gear()
      end
      -- return UIAction.HANDLED
    end,
  }
  self.ui:append_child(prev_button)
  table.insert(self._pagination_controls, prev_button)

  local page_info = Text.new {
    function()
      return {
        {
          text = string.format(
            "Page %d / %d",
            self.current_page,
            self.total_pages
          ),
          color = Colors.white,
          font = Asset.fonts.typography.paragraph_md,
        },
      }
    end,
    box = Box.new(
      Position.new(
        start_x + button_width * 2 + button_spacing * 2,
        pagination_y + 5
      ),
      150,
      30
    ),
    font = Asset.fonts.typography.paragraph_md,
  }
  self.ui:append_child(page_info)
  table.insert(self._pagination_controls, page_info)

  local next_button = ButtonElement.new {
    box = Box.new(
      Position.new(start_x + button_width + button_spacing, pagination_y),
      button_width,
      button_height
    ),
    label = ">",
    on_click = function()
      if self.current_page < self.total_pages then
        self.current_page = self.current_page + 1
        self:display_gear()
      end
      -- return UIAction.HANDLED
    end,
  }
  self.ui:append_child(next_button)
  table.insert(self._pagination_controls, next_button)
end

function gear_menu:keypressed(key)
  if key == "escape" then
    State.mode = GameModes.MAIN_MENU
    return true
  elseif key == "left" and self.current_page > 1 then
    self.current_page = self.current_page - 1
    self:display_gear()
    return true
  elseif key == "right" and self.current_page < self.total_pages then
    self.current_page = self.current_page + 1
    self:display_gear()
    return true
  end
  return false
end

return require("vibes.base-mode").wrap(gear_menu)
