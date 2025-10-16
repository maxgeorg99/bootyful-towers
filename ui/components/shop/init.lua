local ButtonElement = require "ui.elements.button"
-- local ExitShop = require "vibes.action.exit-shop"
local Img = require "ui.components.img"
local OpenForge = require "vibes.action.open-forge"
local OpenCardUpgrade = require "vibes.action.open-card-upgrade"
local Pack = require "ui.components.shop.pack"
local PileElement = require "ui.components.pile"
local PlayerHUD = require "ui.components.player.hud"
local ShopCard = require "ui.components.card.shop-card"
local Text = require "ui.components.text"

local CardFactory = require "vibes.factory.card-factory"
local PackFactory = require("vibes.factory.pack-factory").PackFactory

-- Specialized reroll button that extends the new button system

---@class ui.components.shop.RerollButton.Opts
---@field cost_getter fun() :number
---@field label_text string
---@field on_click fun()
---@field box ui.components.Box

---@class ui.components.shop.RerollButton : elements.Button
---@field init fun(self:ui.components.shop.RerollButton, opts: ui.components.shop.RerollButton.Opts)
---@field new fun( opts: ui.components.shop.RerollButton.Opts)
local RerollButton =
  class("ui.components.shop.RerollButton", { super = ButtonElement })

function RerollButton:init(opts)
  local cost_getter = opts.cost_getter
  local label_text = opts.label_text
  local base_on_click = opts.on_click

  local on_click = function()
    local cost = cost_getter()
    if State.player.gold >= cost then
      base_on_click()
    end
  end

  ButtonElement.init(self, {
    box = opts.box,
    label = "",
    on_click = on_click,
    kind = "filled",
  })

  self.cost_getter = cost_getter
  self.label_text = label_text
end

function RerollButton:_render()
  local x, y, width, height = self:get_geo()
  local cost = self.cost_getter()
  local can_afford = State.player.gold >= cost
  local color = can_afford and { 1, 1, 1, 1 } or { 1, 0.3, 0.3, 0.5 }

  -- Draw background using parent render
  ButtonElement._render(self)

  -- Draw dice icon
  love.graphics.setColor(color)
  local icon_scale = 2.8
  local icon_x = x + width / 2
  local icon_y = y + 8 + height / 2
  love.graphics.draw(
    Asset.sprites.dice_icon,
    icon_x,
    icon_y,
    0,
    icon_scale,
    icon_scale,
    Asset.sprites.dice_icon:getWidth() / 2,
    Asset.sprites.dice_icon:getHeight() / 2
  )

  -- Draw cost text
  love.graphics.setFont(Asset.fonts.insignia_16)
  love.graphics.setColor(color)
  love.graphics.printf(
    self.label_text .. ": " .. cost,
    x,
    y + 8,
    width,
    "center"
  )
end

-- Specialized gear icon button that extends the new button system
local GearIconButton =
  class("ui.components.shop.GearIconButton", { super = ButtonElement })

function GearIconButton:init(opts)
  ButtonElement.init(self, {
    box = opts.box,
    label = "",
    on_click = opts.on_click,
    kind = "filled",
  })
end

function GearIconButton:_render()
  local x, y, width, height = self:get_geo()

  -- Draw background using parent render
  ButtonElement._render(self)

  -- Draw gear icon background
  love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
  love.graphics.rectangle("fill", x, y, width, height, 8, 8)

  -- Draw gear icon (use a gear sprite if available, otherwise draw a simple gear shape)
  love.graphics.setColor(1, 1, 1, 1)
  if Asset.sprites.gear_icon then
    local scale = math.min(
      width / Asset.sprites.gear_icon:getWidth(),
      height / Asset.sprites.gear_icon:getHeight()
    ) * 0.8
    local icon_x = x + (width - Asset.sprites.gear_icon:getWidth() * scale) / 2
    local icon_y = y
      + (height - Asset.sprites.gear_icon:getHeight() * scale) / 2
    love.graphics.draw(Asset.sprites.gear_icon, icon_x, icon_y, 0, scale, scale)
  else
    -- Fallback: draw a simple gear-like shape
    love.graphics.setColor(0.8, 0.8, 0.8, 1)
    local center_x = x + width / 2
    local center_y = y + height / 2
    local radius = math.min(width, height) * 0.3
    love.graphics.circle("fill", center_x, center_y, radius)
    love.graphics.setColor(0.4, 0.4, 0.4, 1)
    love.graphics.circle("fill", center_x, center_y, radius * 0.4)
  end

  -- Add label
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setFont(Asset.fonts.typography.paragraph_sm)
  love.graphics.printf("GEAR", x, y + height - 15, width, "center")
end

local EXIT_WIDTH = 300
local EXIT_HEIGHT = 115
local PADDING = 35

-- Pack display constants
local PACK_WIDTH = 200
local PACK_HEIGHT = 260
local PACK_SPACING = 15
local PACKS_START_X = 500 -- Adjusted to keep roughly same center
local PACKS_Y = 250 -- Upper zone for packs

-- Single card display constants
-- Make cards a bit smaller than packs
local SINGLE_CARD_WIDTH = 180 -- Slightly smaller than pack width (200)
local SINGLE_CARD_HEIGHT = 240 -- Slightly smaller than pack height (260)
local SINGLE_CARD_SPACING = PACK_SPACING + (PACK_WIDTH - SINGLE_CARD_WIDTH) -- Match pack spacing for vertical alignment

-- Adjust start position to center the smaller cards
local SINGLE_CARDS_START_X = PACKS_START_X + (PACK_WIDTH - SINGLE_CARD_WIDTH)
local SINGLE_CARDS_Y = 640 -- Lower zone for single cards

-- Reroll button constants
local REROLL_BUTTON_WIDTH = 150
local REROLL_BUTTON_HEIGHT = 100
local REROLL_BUTTONS_X = 270

---@class components.shop.UI.Opts

---@class ShopCardItem
---@field card_element components.Card
---@field price number
---@field price_text component.Text

---@class (exact) components.shop.UI : Element
---@field new fun(opts: components.shop.UI.Opts): components.shop.UI
---@field packs components.shop.Pack[]
---@field single_cards ShopCardItem[]
---@field cost_to_reroll_packs number
---@field cost_to_reroll_single_cards number
---@field random table
---@field reroll_button ui.components.shop.RerollButton
---@field single_card_reroll_button ui.components.shop.RerollButton
---@field deck_pile components.Pile
---@field has_used_forge boolean
---@field forge_button ui.components.ScaledImg
local ShopUI = class("components.shop.UI", { super = Element })

---@param opts components.shop.UI.Opts
---@return components.shop.UI
function ShopUI:init(opts)
  validate(opts, {})

  local box = Box.new(
    Position.new(0, 0),
    Config.window_size.width,
    Config.window_size.height
  )

  Element.init(self, box)
  self.name = "ShopUI"
  self.packs = {}
  self.single_cards = {}
  self.cost_to_reroll_packs = 100
  self.cost_to_reroll_single_cards = 100
  self.random = require("vibes.engine.random").new { name = "shop-packs" }

  self:_add_background()
  self:_add_player_hud()
  self:_add_deck_pile()
  self:_add_forge_button()
  self:_add_gear_icon()
  self:_add_packs()
  self:_add_single_cards()
  self:_add_reroll_buttons()
  self:_add_exit_button()

  return self
end

-- Calculate card price based on rarity
---@param card vibes.Card
---@return number
function ShopUI:_get_card_price(card)
  local rarity_prices = {
    [Rarity.COMMON] = 60, -- Doubled from 30
    [Rarity.UNCOMMON] = 100, -- Doubled from 50
    [Rarity.RARE] = 160, -- Doubled from 80
    [Rarity.EPIC] = 240, -- Doubled from 120
    [Rarity.LEGENDARY] = 400, -- Doubled from 200
  }

  return rarity_prices[card.rarity] or 30
end

function ShopUI:_add_packs()
  -- Generate 3 packs of random types (mix of card packs and gear packs)
  for i = 1, 3 do
    local pack_data

    -- -- Randomly decide between card pack and gear pack
    if self.random:random() < 0.7 then -- 70% chance for card packs
      -- Generate a random card pack (TOWER or MODIFIER)
      pack_data = PackFactory:generate_random_card_pack()
    else
      -- Generate a gear pack if possible
      if PackFactory:can_generate_gear_pack() then
        pack_data = PackFactory:generate_gear_pack()
      else
        -- Fallback to card pack if no gear available
        pack_data = PackFactory:generate_random_card_pack()
      end
    end

    local x = PACKS_START_X + (i - 1) * (PACK_WIDTH + PACK_SPACING)
    local y = PACKS_Y

    local pack = Pack.new {
      box = Box.new(Position.new(x, y), PACK_WIDTH, PACK_HEIGHT),
      pack = pack_data,
      on_click = function(clicked_pack) self:_purchase_pack(clicked_pack) end,
    }

    pack.z = Z.SHOP_INTERACTABLES
    self.packs[i] = pack
    self:append_child(pack)
  end
end

function ShopUI:reroll_packs()
  if not State.player:use_gold(self.cost_to_reroll_packs) then
    return
  end

  self.cost_to_reroll_packs = self.cost_to_reroll_packs * 2

  -- Remove existing packs
  for _, pack in ipairs(self.packs) do
    self:remove_child(pack)
  end
  self.packs = {}

  -- Generate new packs
  self:_add_packs()

  -- Update reroll button state
  self:_update_reroll_button_state()
end

---@param pack vibes.ShopPack
function ShopUI:_purchase_pack(pack)
  logger.info(
    "Attempting to purchase pack: %s for %d gold",
    pack.name,
    pack.cost
  )

  -- Check if player has enough gold
  if State.player.gold >= pack.cost then
    -- Deduct the gold first
    State.player:use_gold(pack.cost)
    self:_update_reroll_button_state()

    self:_remove_pack_from_shop(pack)

    -- Determine pack type and use appropriate opening action
    local card_pack = pack:get_card_pack()
    local gear_pack = pack:get_gear_pack()

    if card_pack then
      -- This is a CardPack
      local CardPackOpening = require "vibes.action.card-pack-opening"
      ActionQueue:add(CardPackOpening.new {
        pack = card_pack,
        on_complete = function() logger.info "Card pack opening completed" end,
      })
    elseif gear_pack then
      -- This is a GearPack
      local GearPackOpening = require "vibes.action.gear-pack-opening"
      ActionQueue:add(GearPackOpening.new {
        pack = gear_pack,
        on_complete = function() logger.info "Gear pack opening completed" end,
      })
    else
      logger.error("Unknown pack type: %s", pack.name)
    end
  else
    logger.info(
      "Player cannot afford this pack. Has %d gold, needs %d",
      State.player.gold,
      pack.cost
    )
  end
end

-- Helper function to create reroll buttons
---@param box ui.components.Box
---@param cost_getter fun(): number
---@param label_text string
---@param on_click fun()
---@return ui.components.shop.RerollButton
function ShopUI:_create_reroll_button(box, cost_getter, label_text, on_click)
  local button = RerollButton.new {
    label = label_text,
    box = box,
    cost_getter = cost_getter,
    label_text = label_text,
    on_click = on_click,
  }

  button.z = Z.SHOP_INTERACTABLES
  return button
end

function ShopUI:_add_reroll_buttons()
  -- Pack reroll button
  local pack_reroll_box = Box.new(
    Position.new(REROLL_BUTTONS_X, 400),
    REROLL_BUTTON_WIDTH,
    REROLL_BUTTON_HEIGHT
  )

  self.reroll_button = self:_create_reroll_button(
    pack_reroll_box,
    function() return self.cost_to_reroll_packs end,
    "Packs",
    function() self:reroll_packs() end
  )
  self:append_child(self.reroll_button)

  -- Single card reroll button
  local single_card_reroll_box = Box.new(
    Position.new(REROLL_BUTTONS_X, 750),
    REROLL_BUTTON_WIDTH,
    REROLL_BUTTON_HEIGHT
  )

  self.single_card_reroll_button = self:_create_reroll_button(
    single_card_reroll_box,
    function() return self.cost_to_reroll_single_cards end,
    "Cards",
    function() self:reroll_single_cards() end
  )

  self:append_child(self.single_card_reroll_button)

  -- Initial state update
  self:_update_reroll_button_state()
  self:_update_single_card_reroll_button_state()
end

function ShopUI:_update_reroll_button_state()
  if self.reroll_button then
    local can_afford = State.player.gold >= self.cost_to_reroll_packs
    self.reroll_button:set_interactable(can_afford)
  end
end

function ShopUI:_update_single_card_reroll_button_state()
  if self.single_card_reroll_button then
    local can_afford = State.player.gold >= self.cost_to_reroll_single_cards
    self.single_card_reroll_button:set_interactable(can_afford)
  end
end

function ShopUI:_add_single_cards()
  local seen = {}

  -- Generate 3 random single cards
  for i = 1, 3 do
    local card = CardFactory.new_tower_card()
    while seen[card.name] do
      card = CardFactory.new_tower_card()
    end
    seen[card.name] = true

    local card_price = self:_get_card_price(card)

    local x = SINGLE_CARDS_START_X
      + (i - 1) * (SINGLE_CARD_WIDTH + SINGLE_CARD_SPACING)
    local y = SINGLE_CARDS_Y

    ---@type hooks.OnShopInfoResult
    local info = { price = card_price, card = card, pack = nil }
    State.gear_manager:for_gear_in_active_gear(
      function(gear) gear.hooks.on_shop_info(gear, info) end
    )

    -- Create unique ID for this card instance
    local card_id = "shop_card_" .. i .. "_" .. love.timer.getTime()

    local card_element = ShopCard.new {
      box = Box.new(Position.new(x, y), SINGLE_CARD_WIDTH, SINGLE_CARD_HEIGHT),
      -- z = Z.SHOP_TOWER_TOOLTIP - 5000,
      card = card,
      on_click = function() self:_purchase_single_card_by_id(card_id) end,
      on_update = function(card_element, dt)
        local can_afford = State.player.gold >= card_price
        card_element:set_color(
          can_afford and { 1, 1, 1, 1 } or { 0.4, 0.1, 0.1, 1 }
        )
      end,
    }
    self:append_child(card_element)

    -- Add price display below the card
    local price_text = Text.new {
      function() return "{gold:" .. card_price .. "}" end,
      box = Box.new(
        Position.new(x, y + SINGLE_CARD_HEIGHT + 5),
        SINGLE_CARD_WIDTH,
        20
      ),
      font = Asset.fonts.typography.paragraph_md,
      text_align = "center",
    }

    price_text.z = Z.SHOP_INTERACTABLES

    self:append_child(price_text)

    -- Store card data with unique ID
    self.single_cards[card_id] = {
      card_element = card_element,
      price = card_price,
      price_text = price_text,
      card = card,
      id = card_id,
    }
  end
end

function ShopUI:reroll_single_cards()
  if not State.player:use_gold(self.cost_to_reroll_single_cards) then
    return
  end

  self.cost_to_reroll_single_cards = self.cost_to_reroll_single_cards * 2

  -- Remove existing single cards from UI and clear array
  for card_id, shop_card in pairs(self.single_cards) do
    self:remove_child(shop_card.card_element)
    self:remove_child(shop_card.price_text)
  end

  self.single_cards = {}

  -- Generate new single cards
  self:_add_single_cards()

  -- Update reroll button states
  self:_update_reroll_button_state()
  self:_update_single_card_reroll_button_state()
end

---@param card_id string
function ShopUI:_purchase_single_card_by_id(card_id)
  local shop_card = self.single_cards[card_id]
  if not shop_card then
    logger.error("No shop card found with id %s", card_id)
    return
  end

  local card_price = shop_card.price
  local card = shop_card.card

  logger.info(
    "Attempting to purchase single card: %s for %d gold",
    card.name,
    card_price
  )

  if State.player.gold >= card_price then
    State.player:use_gold(card_price)
    self:_remove_single_card_from_shop_by_id(card_id)

    -- Add card directly to deck
    State.deck:add_card(card)

    -- Update button states after purchase
    self:_update_reroll_button_state()
    self:_update_single_card_reroll_button_state()

    logger.info("Successfully purchased and added card %s to deck", card.name)
  else
    logger.info(
      "Player cannot afford this card. Has %d gold, needs %d",
      State.player.gold,
      card_price
    )
  end
end

---@param card_id string
function ShopUI:_remove_single_card_from_shop_by_id(card_id)
  local shop_card = self.single_cards[card_id]
  if not shop_card then
    logger.error("No shop card found with id %s to remove", card_id)
    return
  end

  -- Remove from UI
  self:remove_child(shop_card.card_element)
  self:remove_child(shop_card.price_text)

  -- Remove from array completely
  self.single_cards[card_id] = nil

  logger.info("Removed card %s from shop", shop_card.card.name)
end

-- Cursor Slop from Begin this might not go here
---@param pack vibes.ShopPack
function ShopUI:_remove_pack_from_shop(pack)
  -- Find and remove the pack from the packs array and UI
  for i, shop_pack in ipairs(self.packs) do
    if shop_pack.pack == pack then
      -- Remove from UI
      self:remove_child(shop_pack)
      -- Remove from packs array
      table.remove(self.packs, i)
      logger.info("Removed pack %s from shop", pack.name)
      break
    end
  end
end

function ShopUI:_add_player_hud()
  local player_hud = PlayerHUD {}
  player_hud.z = Z.SHOP_INTERACTABLES
  self:append_child(player_hud)
end

function ShopUI:_add_deck_pile()
  -- Deck pile constants
  local DECK_PILE_ICON_SIZE = 80
  local DECK_PILE_X = Config.window_size.width - DECK_PILE_ICON_SIZE - PADDING
  local DECK_PILE_Y = PADDING

  self.deck_pile = PileElement.new {
    name = "Deck",
    cards = State.deck.draw_pile,
    box = Box.new(
      Position.new(DECK_PILE_X, DECK_PILE_Y),
      DECK_PILE_ICON_SIZE,
      DECK_PILE_ICON_SIZE
    ),
    icon = Asset.sprites.deck_l,
    z = Z.SHOP_PILE_Z,
  }

  self:append_child(self.deck_pile)
end

function ShopUI:_add_forge_button()
  self.has_used_forge = false

  -- Forge/Upgrade button constants - positioned left of gear icon
  local BUTTON_SIZE = 250
  local BUTTON_X = 1450
  local BUTTON_Y = 425

  local ScaledImg = require "ui.components.scaled-img"

  -- Check if player is mage - if so, show card upgrade instead of forge
  if State.selected_character == CharacterKind.MAGE then
    -- Mage gets card upgrade button with upgrade icon
    self.forge_button = ScaledImg.new {
      box = Box.new(
        Position.new(BUTTON_X, BUTTON_Y),
        BUTTON_SIZE,
        BUTTON_SIZE
      ),
      texture = Asset.sprites.upgrade_icon,
      scale_style = "fit",
      on_click = function()
        ActionQueue:add(OpenCardUpgrade.new {
          name = "OpenCardUpgrade",
          on_success = function() self.has_used_forge = true end,
        })
      end,
      interactable = true,
      z = Z.SHOP_INTERACTABLES,
    }
  else
    -- Blacksmith and other classes get forge button with anvil icon
    self.forge_button = ScaledImg.new {
      box = Box.new(
        Position.new(BUTTON_X, BUTTON_Y),
        BUTTON_SIZE,
        BUTTON_SIZE
      ),
      texture = Asset.sprites.forge_anvil,
      scale_style = "fit",
      on_click = function()
        ActionQueue:add(OpenForge.new {
          name = "OpenForge",
          on_success = function() self.has_used_forge = true end,
        })
      end,
      interactable = true,
      z = Z.SHOP_INTERACTABLES,
    }
  end

  self:append_child(self.forge_button)
end

function ShopUI:_add_gear_icon()
  -- Gear icon constants - positioned below deck pile
  local GEAR_ICON_SIZE = 80
  local GEAR_ICON_X = Config.window_size.width - GEAR_ICON_SIZE - PADDING
  local GEAR_ICON_Y = PADDING + GEAR_ICON_SIZE + 20 -- Below deck pile with gap

  local gear_icon = GearIconButton.new {
    box = Box.new(
      Position.new(GEAR_ICON_X, GEAR_ICON_Y),
      GEAR_ICON_SIZE,
      GEAR_ICON_SIZE
    ),
    on_click = function() self:_open_gear_management() end,
  }

  gear_icon.z = Z.SHOP_INTERACTABLES
  self:append_child(gear_icon)
end

function ShopUI:_open_gear_management()
  logger.info "Opening shop gear management overlay"

  -- Check if Quiet Baby! gear is equipped and start special sound if so
  State.gear_manager:for_gear_in_active_gear(function(gear)
    if gear.name == "Quiet Baby!" then
      SoundManager:play_pointcrow_crying_special()
    end
  end)

  -- Create inventory overlay similar to gear pack opening
  local Container = require "ui.components.container"
  local Inventory = require "ui.components.inventory"
  local ScaledImg = require "ui.components.scaled-img"

  local overlay = Container.new {
    box = Box.new(
      Position.new(0, 0),
      Config.window_size.width,
      Config.window_size.height
    ),
    -- Remove dark background to let armory background show through
    z = Z.GEAR_SELECTION_OVERLAY,
  }

  -- Add armory background
  local background_img = ScaledImg.new {
    box = Box.new(
      Position.new(0, 0),
      Config.window_size.width,
      Config.window_size.height
    ),
    texture = Asset.sprites.armory_background,
    scale_style = "stretch",
  }
  background_img.z = 1 -- Behind everything else
  overlay:append_child(background_img)

  -- Add escape key handling to close overlay and stop sound
  overlay._update = function(self, dt)
    if love.keyboard.isDown "escape" then
      SoundManager:stop_pointcrow_crying()
      UI.root:remove_child(overlay)
      logger.info "Closed gear management overlay via escape key"
    end
  end

  UI.root:append_child(overlay)

  local inventory = Inventory.new {
    box = Box.fullscreen(),
    z = Z.GEAR_SELECTION_INVENTORY,
  }
  overlay:append_child(inventory)

  -- Add close button
  local close_button = ButtonElement.new {
    box = Box.new(
      Position.new(
        Config.window_size.width - 140,
        Config.window_size.height - 80
      ),
      100,
      40
    ),
    label = "Close",
    on_click = function()
      -- Stop the special sound when closing inventory
      SoundManager:stop_pointcrow_crying()

      UI.root:remove_child(overlay)
      logger.info "Closed gear management overlay"
    end,
  }
  close_button.z = Z.GEAR_SELECTION_UI
  overlay:append_child(close_button)
end

function ShopUI:_add_background()
  local scale_w = Config.window_size.width
    / Asset.sprites.shop_background:getWidth()
  local scale_h = Config.window_size.height
    / Asset.sprites.shop_background:getHeight()

  local img = Img.new(Asset.sprites.shop_background, scale_w, scale_h)
  img:set_pos(Position.zero())
  img.z = Z.SHOP_BACKGROUND

  self:append_child(img)
end

function ShopUI:_add_exit_button()
  local x = 1425
  local y = 810

  local exit = ButtonElement.new {
    box = Box.new(Position.new(x, y), EXIT_WIDTH, EXIT_HEIGHT),
    label = "Back To Game",
    on_click = function() State.mode = ModeName.MAP end,
  }

  self:append_child(exit)
end

function ShopUI:_render() end

function ShopUI:_update(dt)
  self:_update_reroll_button_state()
  self:_update_single_card_reroll_button_state()

  if self.has_used_forge then
    self.forge_button:set_interactable(false)
  else
    self.forge_button:set_interactable(true)
  end
end

return ShopUI
