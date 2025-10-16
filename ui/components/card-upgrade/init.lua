local Hand = require "ui.components.hand"
local ScaledImg = require "ui.components.scaled-img"
local Text = require "ui.components.text"
local TowerUpgradeButton = require "ui.elements.upgrade-button"
local text_utils = require "utils.text"

local CARD_WIDTH = Config.ui.card.new_width
local CARD_HEIGHT = Config.ui.card.new_height

local BaseCard = require "ui.components.card"

---@class components.CardUpgradeCard : components.Card
---@field new fun(opts: components.Card.Opts): components.CardUpgradeCard
local CardUpgradeCard = class("components.CardUpgradeCard", { super = BaseCard })

---@param opts components.Card.Opts
function CardUpgradeCard:init(opts)
  local box = Box.new(Position.new(0, 0), CARD_WIDTH * 2, CARD_HEIGHT * 2)

  ---@diagnostic disable-next-line: cast-type-mismatch
  ---@cast opts components.Card.Opts

  opts.box = box
  opts.card = opts.card
  BaseCard.init(self, opts)
  self.targets.scale = 0.4

  self.name = "CardUpgradeCard"
end

function CardUpgradeCard:get_geo()
  local GameCard = require "ui.components.card.game-card"
  return GameCard.get_geo(self)
end

function CardUpgradeCard:get_rotation()
  local GameCard = require "ui.components.card.game-card"
  return GameCard.get_rotation(self)
end

---@class components.CardUpgradeUI : Element
---@field new fun(opts: components.CardUpgradeUI.Opts): components.CardUpgradeUI
---@field hand components.Hand
---@field on_complete fun()
---@field on_cancel fun()
---@field upgrade_popup ui.components.TowerUpgradePopup?
---@field dimmable Element?
local CardUpgradeUI = class("components.CardUpgradeUI", { super = Element })

---@class components.CardUpgradeUI.Opts
---@field on_complete fun()
---@field on_cancel fun()

---@param opts components.CardUpgradeUI.Opts
function CardUpgradeUI:init(opts)
  Element.init(self, Box.fullscreen(), {
    name = "CardUpgradeUI",
    z = Z.FORGE,
    interactable = true,
  })

  self.on_complete = opts.on_complete
  self.on_cancel = opts.on_cancel

  -- Background
  self:append_child(ScaledImg.new {
    box = Box.fullscreen(),
    texture = Asset.sprites.shop_background,
    scale_style = "stretch",
  })

  -- Title
  local title = Text.new {
    function() return "Select a Tower Card to Upgrade (100 Gold)" end,
    box = Box.new(
      Position.new(0, 80),
      Config.window_size.width,
      60
    ),
    font = Asset.fonts.insignia_48,
    text_align = "center",
  }
  title.z = Z.FORGE + 10
  self:append_child(title)

  self:_create_hand()

  -- Exit button
  local ButtonElement = require "ui.elements.button"
  local exit_button = ButtonElement.new {
    box = Box.new(
      Position.new(
        Config.window_size.width - 350 - 35,
        Config.window_size.height - 100 - 35
      ),
      350,
      100
    ),
    label = "Cancel",
    on_click = function()
      self.on_cancel()
      UI.root:remove_child(self)
    end,
  }
  exit_button.z = Z.FORGE + 10
  self:append_child(exit_button)
end

function CardUpgradeUI:_create_hand()
  State.deck:reset()

  local cards = {}
  for _, card in ipairs(State.deck:get_all_cards()) do
    if card.kind == CardKind.TOWER then
      table.insert(cards, card)
    end
  end

  if #cards == 0 then
    logger.warn("No tower cards found in deck for upgrade")
    -- Show message and auto-close
    local Container = require "ui.components.container"
    local msg = Text.new {
      function() return "No tower cards available to upgrade!" end,
      box = Box.new(
        Position.new(0, Config.window_size.height / 2 - 50),
        Config.window_size.width,
        100
      ),
      font = Asset.fonts.typography.h1,
      text_align = "center",
    }
    msg.z = Z.FORGE + 10
    self:append_child(msg)

    -- Auto-close after 2 seconds
    State:add_callback(function()
      self.on_cancel()
      UI.root:remove_child(self)
    end, 2)
    return
  end

  local hand_height = Config.ui.card.new_height * 0.6
  local hand_padding = 0.1 * Config.window_size.width
  local start_of_hand =
    Position.new(hand_padding, Config.window_size.height / 2 - hand_height / 2)

  -- Create a card creation function for the hand
  local function create_card(card)
    ---@cast card vibes.TowerCard
    local card_element = CardUpgradeCard.new {
      card = card,

      ---@param card_element components.CardUpgradeCard
      on_click = function(card_element)
        self:_show_upgrade_options(card_element.card)
        return UIAction.HANDLED
      end,
    }
    card_element:set_z(Z.FORGE_HAND + 1)
    return card_element
  end

  self.hand = Hand.new {
    box = Box.new(
      start_of_hand,
      Config.window_size.width - hand_padding * 2,
      hand_height
    ),
    cards = cards,
    create_card = create_card,
    z = Z.FORGE_HAND,
  }
  self:append_child(self.hand)
end

---@param tower_card vibes.TowerCard
function CardUpgradeUI:_show_upgrade_options(tower_card)
  local tower = tower_card.tower

  -- Get upgrade options using the same system as tower level-up
  local upgrades = State:get_tower_upgrade_options(tower)

  if #upgrades == 0 then
    logger.warn("No upgrades available for tower: %s", tower.name)
    return
  end

  -- Create dimmed background
  self.dimmable = Element.new(Box.fullscreen(), {
    z = Z.MAX - 1,
    render = function()
      love.graphics.setColor(Colors.black:opacity(0.5))
      love.graphics.rectangle(
        "fill",
        0,
        0,
        Config.window_size.width,
        Config.window_size.height
      )
    end,
  })
  UI.root:append_child(self.dimmable)

  -- Create a custom centered upgrade popup layout
  local layout = Layout.new {
    name = "CardUpgradeButtons",
    box = Box.new(
      Position.new(
        Config.window_size.width / 2,
        Config.window_size.height / 2
      ),
      0,
      0
    ),
    z = Z.MAX,
    flex = {
      justify_content = "center",
      align_items = "center",
      direction = "row",
      gap = 0,
    },
  }

  for _, upgrade in ipairs(upgrades) do
    local op = upgrade.operations[1]

    local value = text_utils.format_number(op.operation.value)

    if op.field == TowerStatField.CRITICAL then
      value = text_utils.format_number(math.floor(op.operation.value * 100))
        .. "%"
    end

    local upgrade_btn = TowerUpgradeButton.new {
      position = Position.zero(),
      icon_type = TowerStatFieldIcon[op.field],
      rarity = upgrade.rarity,
      value = function() return value end,
      on_click = function()
        -- Level up the tower first (this increments level and card slots)
        tower.experience_manager:level_up { interactive = false }

        -- Apply the upgrade to the tower
        upgrade:apply(tower)
        tower.stats_manager:update(0)

        -- Clean up
        UI.root:remove_child(self.dimmable)
        self.dimmable = nil

        -- Complete the upgrade process
        self.on_complete()
        UI.root:remove_child(self)

        logger.info(
          "Applied upgrade %s to tower %s (now level %d)",
          upgrade.name,
          tower.name,
          tower.level
        )
      end,
      description = upgrade.name,
    }

    layout:set_width(layout:get_width() + upgrade_btn:get_width())

    layout:append_child(upgrade_btn)
  end

  -- Center the layout
  layout:set_x(layout:get_x() - layout:get_width() / 2)

  self.upgrade_popup = layout
  self.dimmable:append_child(layout)
end

function CardUpgradeUI:_update(dt)
  -- No need to handle escape here - the action handles it
end

function CardUpgradeUI:_render() end

return CardUpgradeUI
