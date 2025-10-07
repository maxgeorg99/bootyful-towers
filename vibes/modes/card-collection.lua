local ButtonElement = require "ui.elements.button"
local Container = require "ui.components.container"
local DisplayCard = require "ui.components.card.display-card"
local GameModes = require "vibes.enum.mode-name"
local Text = require "ui.components.text"

---@class (exact) vibes.CardCollection : vibes.BaseMode
---@field world_map vibes.Texture
---@field ui Element
---@field cards vibes.Card[]
---@field current_page number
---@field cards_per_page number
---@field total_pages number
---@field displayed_cards components.DisplayCard[]
---@field _pagination_controls Element[]
local card_collection = {}

-- Cards per page in the grid (centered like gear collection)
local CARDS_PER_PAGE = 8 -- 4 columns x 2 rows centered on screen
local CARD_SCALE = 0.75 -- 25% smaller than original size

--- Collect all possible cards from the registry, sorted by type
function card_collection:_collect_all_cards()
  local all_cards = {}
  local cards_registry = require "vibes.state.cards"

  -- Collect cards by type in order: TOWER, ENHANCEMENT, AURA
  for _, card_kind in ipairs {
    CardKind.TOWER,
    CardKind.ENHANCEMENT,
    CardKind.AURA,
  } do
    for _, rarity in ipairs {
      Rarity.COMMON,
      Rarity.UNCOMMON,
      Rarity.RARE,
      Rarity.EPIC,
      Rarity.LEGENDARY,
    } do
      local card_list = cards_registry[card_kind]
        and cards_registry[card_kind][rarity]
      if card_list then
        for _, card_entry in ipairs(card_list) do
          local card = card_entry.card()
          card.rarity = rarity -- Ensure correct rarity
          table.insert(all_cards, card)
        end
      end
    end
  end

  return all_cards
end

--- Calculate card position in centered grid layout (matching gear collection)
---@param index number: 0-based index within current page
---@return number, number: x, y position
function card_collection:_calculate_card_position(index)
  local cards_per_row = 4 -- 4 columns like gear collection
  local card_width = Config.ui.card.new_width * CARD_SCALE
  local card_height = Config.ui.card.new_height * CARD_SCALE
  local card_spacing = Config.ui.card.spacing * 100 -- Convert from 0.3 to pixels

  -- Calculate centered position for card display area (matching gear collection)
  local area_width = Config.window_size.width
    - Config.window_size.padding.left
    - Config.window_size.padding.right
  local area_height = Config.window_size.height - 350

  -- Calculate centered position for card grid within the display area
  local total_grid_width = cards_per_row * card_width
    + (cards_per_row - 1) * card_spacing
  local total_grid_height = 2 * card_height + card_spacing -- 2 rows max

  local start_x = (area_width - total_grid_width) / 2
    + Config.window_size.padding.left
  local start_y = (area_height - total_grid_height) / 2 + 175 -- +175 to account for title and button area

  local row = math.floor(index / cards_per_row)
  local col = index % cards_per_row

  local x = start_x + col * (card_width + card_spacing)
  local y = start_y + row * (card_height + card_spacing)

  return x, y
end

--- Update displayed cards for current page
function card_collection:_update_displayed_cards()
  -- Clear existing cards (but keep title and back button)
  if self.displayed_cards then
    for _, card in ipairs(self.displayed_cards) do
      if card.remove_from_parent then
        card:remove_from_parent()
      end
    end
  end

  -- Clear pagination controls
  if self._pagination_controls then
    for _, control in ipairs(self._pagination_controls) do
      if control.remove_from_parent then
        control:remove_from_parent()
      end
    end
  end

  -- Calculate start and end indices for current page
  local start_idx = (self.current_page - 1) * self.cards_per_page + 1
  local end_idx = math.min(start_idx + self.cards_per_page - 1, #self.cards)

  self.displayed_cards = {}

  -- Display cards for current page
  for i = start_idx, end_idx do
    local card = self.cards[i]
    if card then
      local card_x, card_y = self:_calculate_card_position(i - start_idx)

      -- Scale the actual card box size to make the graphics smaller
      local scaled_width = Config.ui.card.new_width * CARD_SCALE
      local scaled_height = Config.ui.card.new_height * CARD_SCALE

      local display_card = DisplayCard.new {
        box = Box.new(
          Position.new(card_x, card_y),
          scaled_width,
          scaled_height
        ),
        card = card,
      }

      self.ui:append_child(display_card)
      table.insert(self.displayed_cards, display_card)
    end
  end

  -- Add pagination controls (matching gear collection style)
  self:_add_pagination_controls()
end

--- Add pagination controls with both arrow and text buttons
function card_collection:_add_pagination_controls()
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

  local pagination_y = Config.window_size.height * 0.85 -- position at bottom of card area
  local arrow_button_width = Config.ui.time_multiplier_button.width -- reuse existing button width
  local text_button_width = Config.ui.time_multiplier_button.width + 40 -- slightly wider for text
  local button_height = Config.ui.time_multiplier_button.height
  local button_spacing = 15
  local center_x = Config.window_size.width / 2

  -- Calculate total width of all pagination elements
  local total_width = text_button_width * 2
    + arrow_button_width * 2
    + 150
    + button_spacing * 4
  local start_x = center_x - total_width / 2

  -- Previous arrow button
  local prev_arrow_button = ButtonElement.new {
    box = Box.new(
      Position.new(start_x + text_button_width + button_spacing, pagination_y),
      arrow_button_width,
      button_height
    ),
    label = "<",
    interactable = self.current_page > 1,
    on_click = function()
      if self.current_page > 1 then
        self.current_page = self.current_page - 1
        self:_update_displayed_cards()
      end
    end,
  }
  self.ui:append_child(prev_arrow_button)
  table.insert(self._pagination_controls, prev_arrow_button)

  -- Page info
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
        start_x + text_button_width + arrow_button_width + button_spacing * 2,
        pagination_y + 5
      ),
      150,
      30
    ),
    font = Asset.fonts.typography.paragraph_md,
    text_align = "center",
  }
  self.ui:append_child(page_info)
  table.insert(self._pagination_controls, page_info)

  -- Next arrow button
  local next_arrow_button = ButtonElement.new {
    box = Box.new(
      Position.new(
        start_x
          + text_button_width
          + arrow_button_width
          + 150
          + button_spacing * 3,
        pagination_y
      ),
      arrow_button_width,
      button_height
    ),
    label = ">",
    interactable = self.current_page < self.total_pages,
    on_click = function()
      if self.current_page < self.total_pages then
        self.current_page = self.current_page + 1
        self:_update_displayed_cards()
      end
    end,
  }
  self.ui:append_child(next_arrow_button)
  table.insert(self._pagination_controls, next_arrow_button)
end

function card_collection:enter()
  -- Load world map for background (same as gear collection)
  self.world_map = Asset.sprites.world_map

  self.ui = Container.new { box = Box.fullscreen() }
  UI.root:append_child(self.ui)

  -- Collect all cards
  self.cards = self:_collect_all_cards()
  self.current_page = 1
  self.cards_per_page = CARDS_PER_PAGE
  self.total_pages = math.ceil(#self.cards / self.cards_per_page)
  self.displayed_cards = {}

  -- Add title (matching gear collection styling and position)
  local title = Text.new {
    function() return "CARD COLLECTION" end,
    text_align = "center",
    color = Colors.white:get(), -- matching gear collection white color
    font = Asset.fonts.insignia_48,
    box = Box.new(
      Position.new(0, Config.window_size.height * 0.1), -- exactly matching gear collection position
      Config.window_size.width,
      60
    ),
  }
  self.ui:append_child(title)

  -- Add back button (top left corner, matching gear collection)
  local back_button = ButtonElement.new {
    box = Box.new(
      Position.new(
        Config.window_size.padding.left,
        Config.window_size.padding.left
      ),
      Config.ui.menu_buttons.width,
      Config.ui.menu_buttons.height
    ),
    label = "Back to Main Menu",
    on_click = function() State.mode = GameModes.MAIN_MENU end,
  }
  self.ui:append_child(back_button)

  -- Update display
  self:_update_displayed_cards()
end

function card_collection:exit()
  if self.ui then
    UI.root:remove_child(self.ui)
  end
end

function card_collection:update(_) end

function card_collection:draw()
  -- Draw background (same as gear collection)
  love.graphics.setColor(0.1, 0.1, 0.2)
  love.graphics.rectangle(
    "fill",
    0,
    0,
    Config.window_size.width,
    Config.window_size.height
  )

  -- Draw world map to cover the entire screen (same as gear collection)
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

--- Handle keyboard input (matching gear collection)
---@param key string
function card_collection:keypressed(key)
  if key == "escape" then
    State.mode = GameModes.MAIN_MENU
    return true
  elseif key == "left" and self.current_page > 1 then
    self.current_page = self.current_page - 1
    self:_update_displayed_cards()
    return true
  elseif key == "right" and self.current_page < self.total_pages then
    self.current_page = self.current_page + 1
    self:_update_displayed_cards()
    return true
  end
  return false
end

return require("vibes.base-mode").wrap(card_collection)
