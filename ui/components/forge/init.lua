local ForgeUtils = require "ui.components.forge.utils"
local Hand = require "ui.components.hand"
local Label = require "ui.components.label"
local ScaledImg = require "ui.components.scaled-img"
local anim = require "vibes.anim"

local INVALID_SACRIFICE_RARITY =
  "Sacrifice Card has to be within 2 rarity levels of Upgrade Card"

local CARD_WIDTH = Config.ui.card.new_width
local CARD_HEIGHT = Config.ui.card.new_height

local BaseCard = require "ui.components.card"

---@class components.ForgeCard.Opts
---@field card vibes.Card

---@class components.ForgeCard : components.Card
---@field new fun(opts: components.ForgeCard.Opts): components.ForgeCard
---@field forge_container Element?
local ForgeCard = class("components.ForgeCard", { super = BaseCard })

---@param opts components.ForgeCard.Opts
function ForgeCard:init(opts)
  local box = Box.new(Position.new(0, 0), CARD_WIDTH * 2, CARD_HEIGHT * 2)

  ---@diagnostic disable-next-line: cast-type-mismatch
  ---@cast opts components.Card.Opts

  opts.box = box
  opts.card = opts.card
  BaseCard.init(self, opts)
  self.targets.scale = 0.33
  -- GameCard.init(self, opts)

  self.name = "ForgeCard"
end

function ForgeCard:get_geo()
  -- -- TODO: Should probably be eased or something. I don't know right now.
  -- if self.targets.dragged == 1 then
  --   local x, y = State.mouse.x, State.mouse.y
  --   local offset = self:_get_drag_offset()
  --   x = x - offset.x
  --   y = y - offset.y
  --   return x, y, CARD_WIDTH, CARD_HEIGHT
  -- end

  if self.forge_container then
    local x, y, w, h = self.forge_container:get_geo()
    x = x - (CARD_WIDTH * self:get_scale())
    y = y - (CARD_HEIGHT * self:get_scale())

    return x, y, w, h
  end

  local GameCard = require "ui.components.card.game-card"
  return GameCard.get_geo(self)
end

function ForgeCard:get_opacity()
  if self._props.sacrifice_opacity then
    return BaseCard.get_opacity(self) * self._props.sacrifice_opacity
  end

  return BaseCard.get_opacity(self)
end

function ForgeCard:get_rotation()
  if self.forge_container then
    return 0
  end

  local GameCard = require "ui.components.card.game-card"
  return GameCard.get_rotation(self)
end

local CRAFT_WIDTH = 250
local CRAFT_HEIGHT = 80
local EXIT_WIDTH = 350
local EXIT_HEIGHT = 100
local PADDING = 35

---@class components.ForgeUI : Element
---@field new fun(): components.ForgeUI
---@field hand components.Hand
---@field craft ui.components.Button
---@field status_text Element
---@field error_text ui.components.Label
---@field forge_pile components.ForgePile?
---@field exit Element?
---
---@field sacrifice_card components.Card?
---@field sacrifice_element Element?
---
---@field upgrade_card components.Card?
---@field upgrade_element Element?
---@field return_to_shop fun()
local ForgeUI = class("components.ForgeUI", { super = Element })

---@class components.ForgeUI.Opts
---@field return_to_shop fun()

---@param opts components.ForgeUI.Opts
function ForgeUI:init(opts)
  Element.init(self, Box.fullscreen(), {
    name = "ForgeUI",
    z = Z.FORGE,
    interactable = true,
  })

  -- self:set_debug(true)
  self.return_to_shop = opts.return_to_shop
  -- Simple colored background for testing
  self:append_child(ScaledImg.new {
    box = Box.fullscreen(),
    texture = Asset.sprites.forge_background,
    scale_style = "stretch",
  })

  self:append_child(ScaledImg.new {
    box = Box.fullscreen(),
    texture = Asset.sprites.forge_furnace,
    scale_style = "stretch",
  })

  self:append_child(ScaledImg.new {
    box = Box.fullscreen(),
    texture = Asset.sprites.forge_anvil_in_place,
    scale_style = "stretch",
  })

  self:_create_card_holders()
  self:_create_buttons()

  self.error_text =
    Label.new(Asset.fonts.typography.h2, "Error", Colors.red, "center")
  self:append_child(self.error_text)

  self:_create_hand()
end

---@return ForgeCraftState
function ForgeUI:_valid_craft_state()
  if self.upgrade_card == nil or self.sacrifice_card == nil then
    return ForgeCraftState.MISSING
  end

  local u_rarity = ForgeUtils.rarity_to_integer(self.upgrade_card.card.rarity)
  local s_rarity = ForgeUtils.rarity_to_integer(self.sacrifice_card.card.rarity)
  if u_rarity - s_rarity < Config.ui.forge.upgrade_rarity_distance_max then
    return ForgeCraftState.READY
  end
  return ForgeCraftState.INVALID
end

function ForgeUI:_calculate_craft_state()
  local state = self:_valid_craft_state()
  if state == ForgeCraftState.READY then
    self.craft:set_interactable(true)
    self.error_text:set_opacity(0)
  elseif state == ForgeCraftState.INVALID then
    self.craft:set_interactable(false)
    self.error_text:set_opacity(1)
    self.error_text:set_text(INVALID_SACRIFICE_RARITY)
  elseif state == ForgeCraftState.MISSING then
    self.craft:set_interactable(false)
    self.error_text:set_opacity(0)
  end
end

function ForgeUI:_create_hand()
  State.deck:reset()

  local cards = {}
  for _, card in ipairs(State.deck:get_all_cards()) do
    if card.kind == CardKind.ENHANCEMENT then
      table.insert(cards, card)
    end
  end

  local hand_height = Config.ui.card.new_height * 0.5
  local hand_padding = 0.15 * Config.window_size.width
  local start_of_hand =
    Position.new(240, Config.window_size.height - hand_height)

  -- Create a card creation function for the hand
  local function create_card(card)
    local card_element = ForgeCard.new {
      card = card,

      ---@param card_element components.ForgeCard
      on_drag_start = function(card_element) return UIAction.HANDLED end,

      ---@param card_element components.ForgeCard
      on_use = function(card_element)
        -- TODO: This can get in some bad states, so we should handle that better.
        local x, y = State.mouse.x, State.mouse.y
        if self.sacrifice_element:contains_absolute_x_y(x, y) then
          self.sacrifice_card = card_element
          card_element.forge_container = self.sacrifice_element
          table.remove_item(self.hand.cards, card_element.card)
          self.sacrifice_element:append_child(card_element)
          return
        elseif self.upgrade_element:contains_absolute_x_y(x, y) then
          self.upgrade_card = card_element
          card_element.forge_container = self.upgrade_element
          table.remove_item(self.hand.cards, card_element.card)
          self.upgrade_element:append_child(card_element)
          return
        end

        card_element.forge_container = nil
        if not table.find(self.hand.cards, card_element.card) then
          table.insert(self.hand.cards, card_element.card)
        end

        return
      end,

      ---@param card_element components.ForgeCard
      on_drag_end = function(card_element)
        card_element:on_use()
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

function ForgeUI:_create_card_holder(name, position)
  local Container = require "ui.components.container"
  local container = Container.new {
    box = Box.new(position, CARD_WIDTH, CARD_HEIGHT),
    name = name,
  }

  return container
end

function ForgeUI:_create_card_holders()
  self.sacrifice_element =
    self:_create_card_holder("SacrificeElement", Position.new(680, 300))
  self:append_child(self.sacrifice_element)

  self.upgrade_element =
    self:_create_card_holder("UpgradeElement", Position.new(1091, 274))
  self:append_child(self.upgrade_element)
end

function ForgeUI:_create_buttons()
  self.craft = Button.new {
    box = Box.new(Position.new(1386, 490), CRAFT_WIDTH, CRAFT_HEIGHT),
    on_click = function() self:_animate_craft() end,

    interactable = false,
    draw = "Craft",
    font = Asset.fonts.insignia_48,
    default_color = Colors.red,
    hover_color = Colors.dark_red,
  }

  local x = Config.window_size.width - (EXIT_WIDTH + PADDING)
  local y = Config.window_size.height - (EXIT_HEIGHT + PADDING)

  local exit = Button.new {
    box = Box.new(Position.new(x, y), EXIT_WIDTH, EXIT_HEIGHT),
    on_click = function() self.return_to_shop() end,
    interactable = true,
    draw = "Back To Shop",
    font = Asset.fonts.insignia_48,
    default_color = Colors.red,
    hover_color = Colors.dark_red,
  }

  self:append_child(exit)

  self.exit = exit
  self.craft.z = Z.FORGE_PLACED_CARDS
  self:append_child(self.craft)
end

function ForgeUI:_animate_craft()
  if not self.sacrifice_card or not self.upgrade_card then
    return
  end

  -- Disable the craft button during animation
  self.craft:set_interactable(false)

  -- Create animator for this animation sequence
  local sacrifice_orig_y = self.sacrifice_element._props.y
  local upgrade_orig_y = self.upgrade_element._props.y
  local sacrifice_target_y = sacrifice_orig_y + 500
  local upgrade_target_y = upgrade_orig_y + 250

  -- Create animation clip for the craft sequence
  local craft_clip = anim.make_simple_clip("craft_animation", "dummy", {
    { time = 0.0, value = 0 },
    { time = 0.3, value = 1 }, -- Down phase complete
    { time = 0.7, value = 0 }, -- Up phase complete
  })

  -- Create keyframes for sacrifice card Y position
  local sacrifice_channel = anim.channel("sacrifice_y", {
    { time = 0.0, value = sacrifice_orig_y },
    { time = 0.3, value = sacrifice_target_y, ease = anim.Ease.easeOut },
    { time = 0.7, value = sacrifice_orig_y, ease = anim.Ease.easeInOutCubic },
  })

  -- Create keyframes for sacrifice card opacity (fade to 0)
  local sacrifice_opacity_channel = anim.channel("sacrifice_opacity", {
    { time = 0.0, value = 1.0 },
    { time = 0.3, value = 0.0, ease = anim.Ease.easeOut },
  })

  -- Create keyframes for upgrade card Y position
  local upgrade_channel = anim.channel("upgrade_y", {
    { time = 0.0, value = upgrade_orig_y },
    { time = 0.3, value = upgrade_target_y, ease = anim.Ease.easeOut },
    { time = 0.7, value = upgrade_orig_y, ease = anim.Ease.easeInOutCubic },
  })

  -- Create keyframes for upgrade card rotation (90 degrees and back)
  local upgrade_rotation_channel = anim.channel("upgrade_rotation", {
    { time = 0.0, value = 0.0 },
    { time = 0.3, value = math.pi / 2, ease = anim.Ease.easeOut },
    { time = 0.7, value = 0.0, ease = anim.Ease.easeInOutCubic },
  })

  -- Update the clip with the actual channels
  craft_clip.channels = {
    sacrifice_y = sacrifice_channel,
    sacrifice_opacity = sacrifice_opacity_channel,
    upgrade_y = upgrade_channel,
    upgrade_rotation = upgrade_rotation_channel,
  }

  -- Extend animator with the parameters we need
  anim.extend(self.animator, {
    sacrifice_y = { initial = sacrifice_orig_y, rate = 1.0 },
    sacrifice_opacity = { initial = 1.0, rate = 1.0 },
    upgrade_y = { initial = upgrade_orig_y, rate = 1.0 },
    upgrade_rotation = { initial = 0.0, rate = 1.0 },
  })

  -- Play the animation clip
  local track = anim.play(self.animator, craft_clip)

  -- Set up completion callback
  self._craft_track = track
  self._craft_complete_time = 0.7 -- When animation should complete
  self._craft_start_time = love.timer.getTime()
end

function ForgeUI:_perform_craft_upgrade()
  ---@type vibes.Card
  local upgraded_card = self.upgrade_card.card

  if upgraded_card.rarity == Rarity.COMMON then
    upgraded_card.rarity = Rarity.UNCOMMON
  elseif upgraded_card.rarity == Rarity.UNCOMMON then
    upgraded_card.rarity = Rarity.RARE
  elseif upgraded_card.rarity == Rarity.RARE then
    upgraded_card.rarity = Rarity.EPIC
  elseif upgraded_card.rarity == Rarity.EPIC then
    upgraded_card.rarity = Rarity.LEGENDARY
  else
    error "cannot upgrade legendary"
  end

  State.deck:trash_card(self.sacrifice_card.card)
  table.remove_item(self.hand.cards, self.sacrifice_card.card)
  self.hand:remove_child(self.sacrifice_card)
  self.sacrifice_element:remove_child(self.sacrifice_card)
  self.upgrade_element:remove_child(self.upgrade_card)
  table.insert(self.hand.cards, self.upgrade_card.card)
end

function ForgeUI:_update(dt)
  self:_calculate_craft_state()

  -- Handle craft animation
  if self._craft_track then
    -- Update the animation
    anim.update(self.animator, dt)

    -- Apply animated values to elements
    ---@type number
    local sacrifice_y = self.animator.params.sacrifice_y
    ---@type number
    local sacrifice_opacity = self.animator.params.sacrifice_opacity
    ---@type number
    local upgrade_y = self.animator.params.upgrade_y
    ---@type number
    local upgrade_rotation = self.animator.params.upgrade_rotation

    self.sacrifice_element._props.y = sacrifice_y
    self.sacrifice_element._props.opacity = sacrifice_opacity
    self.upgrade_element._props.y = upgrade_y
    self.upgrade_element._props.rotation = upgrade_rotation

    -- Check if animation is complete
    local elapsed = love.timer.getTime() - self._craft_start_time
    if elapsed >= self._craft_complete_time then
      -- Animation complete, perform upgrade if not already done
      if self.sacrifice_card and self.upgrade_card then
        self:_perform_craft_upgrade()
      end

      -- Clean up animation
      anim.stop(self.animator, self._craft_track)
      self._craft_track = nil
      self._craft_complete_time = nil
      self._craft_start_time = nil

      self.return_to_shop()
    end
  end
end
function ForgeUI:_render() end

return ForgeUI
