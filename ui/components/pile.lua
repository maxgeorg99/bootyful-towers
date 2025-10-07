local CardKindList = require "ui.components.card-kind-list"
local Img = require "ui.components.img"
local Overlay = require "ui.components.elements.overlay"
local ScaledImage = require "ui.components.scaled-img"
local Text = require "ui.components.text"

local MARGIN = 40
local CARD_HEIGHT = Config.ui.card.new_height

---@class components.Pile.Opts
---@field name string
---@field cards vibes.Card[] THIS IS READONLY!! DO NOT MODIFY IT!!
---@field icon vibes.Texture
---@field box ui.components.Box
---@field z number?

---@class (exact) components.Pile : Element
---@field new fun(opts: components.Pile.Opts): components.Pile
---@field init fun(self: components.Pile, opts: components.Pile.Opts)
---@field title component.Text
---@field overlay ui.element.Overlay
---@field deck_stats layout.Layout
---@field tower_list CardKindList
---@field enhancement_list CardKindList
---@field aura_list CardKindList
---@field card_container layout.Layout
--
-- Private Fields
---@field _cards_reference vibes.Card[]
local PileElement = class("ui.components.PileElement", { super = Element })

---@param opts components.Pile.Opts
function PileElement:init(opts)
  validate(opts, {
    name = "string",
    cards = List { Card },
    box = Box,
    icon = "userdata",
  })

  Element.init(self, Box.fullscreen(), {
    interactable = false,
    z = F.if_nil(opts.z, Z.PILE_MENU),
  })

  self.name = opts.name
  self._cards_reference = opts.cards

  self:append_child(ScaledImage.new {
    box = opts.box,
    texture = opts.icon,
    scale_style = "fit",
    interactable = true,
    on_click = function()
      self:toggle_overlay()
      return UIAction.HANDLED
    end,
  })

  local text_box = opts.box:clone()
  text_box.position.x = text_box.position.x - text_box.width
  self:append_child(Text.new {
    function() return tostring(#self._cards_reference) end,
    box = text_box,
    font = Asset.fonts.typography.h2,
    color = Colors.white:get(),
    text_align = "center",
    vertical_align = "center",
  })

  self:ensure_overlay_exists()
end

function PileElement:ensure_overlay_exists()
  if self.overlay then
    return -- Already exists
  end

  self.overlay = Overlay.new {
    z = Z.PILE_MENU,
    can_close = true,
    on_close = function()
      -- Cleanup when overlay closes
      self:cleanup_overlay()
    end,
  }
  self.overlay:set_hidden(true)
  self:append_child(self.overlay)

  -- Setup the content inside the overlay
  self:setup_overlay_content()
  self:append_child(self.overlay)
end

function PileElement:cleanup_overlay()
  -- Optional: Add any cleanup logic when overlay closes
  -- Could potentially destroy and recreate overlay if needed for memory management
end

function PileElement:setup_overlay_content()
  -- Create title
  local title_box = Box.new(
    Position.new((Config.window_size.width / 2) - 100, MARGIN * 2),
    200,
    60
  )

  self.title = Text.new {
    string.gsub(
      self.name,
      "(%a)([%w_']*)",
      function(first, rest) return first:upper() .. rest:lower() end
    ),
    font = Asset.fonts.typography.h3,
    box = title_box,
    color = { 1, 1, 1, 1 },
    --     background = { 105 / 255, 72 / 255, 39 / 255, 255 / 255 },
    rounded = 10,
  }
  self.overlay:append_child(self.title)

  -- Create deck stats panel (character info)
  local stats_box = Box.new(
    Position.new(MARGIN, MARGIN * 4),
    200,
    Config.window_size.height - MARGIN * 8
  )

  self.deck_stats = Layout.new {
    name = "DeckStats",
    box = stats_box,
    flex = {
      direction = "column",
      justify_content = "center",
      align_items = "center",
      gap = 4,
    },
  }

  -- Add character sprite
  local character_sprite = State:get_character_sprite()
  local char_scale = 1.1
  local char_img = Img.new(character_sprite, char_scale)
  self.deck_stats:append_child(char_img)

  self.overlay:append_child(self.deck_stats)

  -- Setup card container layout
  self:setup_card_containers()
end

function PileElement:setup_card_containers()
  local content_width = Config.window_size.width - 200 - (MARGIN * 6) -- Account for stats panel
  local content_height = Config.window_size.height - (MARGIN * 8)
  local content_x = 200 + (MARGIN * 4) -- Position after stats panel

  -- Create main container for all card lists
  local container_box =
    Box.new(Position.new(content_x, MARGIN * 4), content_width, content_height)

  self.card_container = Layout.new {
    name = "PileCardContainer",
    box = container_box,
    flex = {
      direction = "column",
      justify_content = "start",
      align_items = "start",
      gap = MARGIN,
    },
  }

  -- Create CardKindList for each type
  local card_kinds = { CardKind.TOWER, CardKind.ENHANCEMENT, CardKind.AURA }
  local card_lists = {}

  for i, kind in ipairs(card_kinds) do
    local kind_box =
      Box.new(Position.new(0, 0), content_width, CARD_HEIGHT + MARGIN)
    print("Creating box:", kind_box)

    local card_list = CardKindList.new {
      cards = self._cards_reference,
      kind = kind,
      box = kind_box,
    }

    -- Add title for each section
    local title_box = Box.new(Position.new(0, -30), content_width, 25)

    local title = Text.new {
      string.upper(kind),
      box = title_box,
      font = Asset.fonts.insignia_18,
      color = Colors.white:get(),
      background = { 0 / 255, 0 / 255, 0 / 255, 90 / 255 },
      align = "left",
      padding = 20,
    }

    card_list:append_child(title)
    table.insert(card_lists, card_list)

    -- Store references for easy access
    if kind == CardKind.TOWER then
      self.tower_list = card_list
    elseif kind == CardKind.ENHANCEMENT then
      self.enhancement_list = card_list
    elseif kind == CardKind.AURA then
      self.aura_list = card_list
    end
  end

  -- Add card lists to the container
  for _, card_list in ipairs(card_lists) do
    self.card_container:append_child(card_list)
  end
  self.overlay:append_child(self.card_container)
end

function PileElement:toggle_overlay()
  logger.debug("click", self.name, #self._cards_reference)

  if #self._cards_reference == 0 then
    UI:create_user_message("No cards in " .. self.name)
    return
  end

  -- Create overlay lazily on first click
  if not self.overlay then
    return self:ensure_overlay_exists()
  end

  if self.overlay:is_hidden() then
    self.overlay:open()
  else
    self.overlay:close()
  end

  return UIAction.HANDLED
end

function PileElement:_render() end

return PileElement
