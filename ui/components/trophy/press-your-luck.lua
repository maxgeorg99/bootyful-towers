local ButtonElement = require "ui.elements.button"
local Text = require "ui.components.text"
local TrophyCardBack = require "ui.components.trophy.card-back"
local rectangle = require "utils.rectangle"

local CardFactory = require "vibes.factory.card-factory"

-- Specialized press your luck button that extends the new button system
local PressYourLuckButton =
  class("ui.components.trophy.PressYourLuckButton", { super = ButtonElement })

function PressYourLuckButton:init(opts)
  ButtonElement.init(self, {
    kind = "filled",
    box = opts.box,
    label = "",
    on_click = opts.on_click,
  })
end

function PressYourLuckButton:_render()
  local x, y, width, height = self:get_geo()

  -- Draw background using parent render
  ButtonElement._render(self)

  -- Custom label based on game state
  local text
  if State.levels:just_completed_main_waves() then
    text = "Start Bonus Waves"
  elseif
    State.levels:is_in_bonus_waves()
    or State.levels:just_completed_bonus_wave()
  then
    text = "Next Bonus Wave"
  else
    text = "Press Your Luck?"
  end

  love.graphics.setFont(Asset.fonts.insignia_24)
  rectangle.center_text_in_rectangle(text, x, y, width, height, 1)
end

-- UI Layout constants
local DEFAULT_W = Config.window_size.width
local DEFAULT_H = Config.window_size.height
local CARD_WIDTH = Config.ui.card.new_width -- Smaller width
local CARD_HEIGHT = Config.ui.card.new_height -- Much smaller height (1/3)
local CARD_SPACING = 40 -- Reduced spacing to fit better

---@class components.trophy.PressYourLuckUI.Opts : Element.Opts
---@field on_complete? fun(): nil
---@field on_choose_shop? fun(): nil
---@field on_choose_level? fun(): nil
---@field rarity Rarity

---@class (exact) components.trophy.PressYourLuckUI : Element
---@field new fun(opts: components.trophy.PressYourLuckUI.Opts): components.trophy.PressYourLuckUI
---@field init fun(self: components.trophy.PressYourLuckUI, opts: components.trophy.PressYourLuckUI.Opts)
---@field trophy_cards vibes.Card[]
---@field _selected vibes.Card | nil
---@field _card_element components.TrophyCardBack
---@field _card_elements components.TrophyCardBack[]
---@field _press_your_luck_button elements.Button
---@field _skip_button elements.Button
---@field _confirm_button elements.Button
---@field _on_complete? fun(): nil
---@field _card vibes.Card?
---@field on_choose_shop? fun(): nil
---@field on_choose_level? fun(): nil
---@field rarity Rarity
local PressYourLuckUI =
  class("components.trophy.PressYourLuckUI", { super = Element })

---@param opts components.trophy.PressYourLuckUI.Opts
function PressYourLuckUI:init(opts)
  validate(opts, {
    on_complete = "function?",
    on_choose_shop = "function?",
    on_choose_level = "function?",
    rarity = Rarity,
  })

  local box = Box.new(Position.new(0, 0), DEFAULT_W, DEFAULT_H)

  Element.init(self, box, {
    z = Z.TROPHY_SELECTION_CARDS,
    interactable = false, -- Let children handle interactions
    created_offset = Position.new(0, Config.window_size.height),
  })

  self.name = "PressYourLuckUI"
  self._selected = nil
  self._card_elements = {}
  self._on_complete = opts.on_complete
  self.on_choose_shop = opts.on_choose_shop
  self.on_choose_level = opts.on_choose_level
  self.rarity = opts.rarity

  -- Generate a trophy card of the determined rarity
  self._card = CardFactory.get_trophy_card_by_rarity(self.rarity)
  print("PYL UI Generated Card: ", self._card.name, self._card.rarity)

  self:_add_layout()
end

function PressYourLuckUI:_add_layout()
  local _, _, w, h = self:get_geo()

  -- Create card elements
  self._card_element_l = TrophyCardBack.new {
    box = Box.new(Position.zero(), CARD_WIDTH, CARD_HEIGHT),
    card = self._card,
    z = Z.TROPHY_SELECTION_CARDS,
    on_click = function() self.on_choose_level() end,
  }

  -- Create card elements
  self._card_element_m = TrophyCardBack.new {
    box = Box.new(Position.zero(), CARD_WIDTH, CARD_HEIGHT),
    card = self._card,
    z = Z.TROPHY_SELECTION_CARDS,
    on_click = function() self.on_choose_level() end,
  }

  -- Create card elements
  self._card_element_r = TrophyCardBack.new {
    box = Box.new(Position.zero(), CARD_WIDTH, CARD_HEIGHT),
    card = self._card,
    z = Z.TROPHY_SELECTION_CARDS,
    on_click = function() self.on_choose_level() end,
  }

  -- Create buttons
  self._press_your_luck_button = PressYourLuckButton.new {
    box = Box.new(Position.zero(), 250, 60),
    on_click = function(_) self.on_choose_level() end,
  }

  self._skip_button = ButtonElement.new {
    box = Box.new(Position.zero(), 250, 60),
    label = "Exit Level to Shop",
    on_click = function() self.on_choose_shop() end,
  }

  -- Create the main layout
  local main_layout = Layout.new {
    name = "PressYourLuckSelection",
    animation_duration = 0,
    box = Box.new(Position.zero(), w, h),
    els = {
      -- Title section
      Layout.col {
        box = Box.new(Position.zero(), w, 150),
        els = {
          Layout.rectangle {
            box = Box.new(Position.zero(), w, 80),
          },
          Text.new {
            function()
              if State.levels:just_completed_main_waves() then
                return "Play Next Bonus Wave To Choose a new Card!"
              elseif
                State.levels:is_in_bonus_waves()
                or State.levels:just_completed_bonus_wave()
              then
                local bonus_num = State.levels:get_current_bonus_wave_number()
                  or 1
                local remaining = 5 - bonus_num + 1
                return string.format(
                  "Continue to next bonus wave (%d remaining) or go to shop!",
                  remaining
                )
              else
                return "Play the wave again for a better reward!"
              end
            end,
            text_align = "center",
            color = Colors.white:get(),
            font = Asset.fonts.typography.h2,
            box = Box.new(Position.zero(), w, 60),
          },
        },
        flex = {
          direction = "column",
          justify_content = "center",
          align_items = "center",
          gap = 30,
        },
      },

      -- Cards section
      Layout.new {
        name = "TrophyCards",
        animation_duration = 0,
        box = Box.new(Position.zero(), w, 500),
        els = {
          self._card_element_l,
          self._card_element_m,
          self._card_element_r,
        },
        flex = {
          direction = "row",
          justify_content = "center",
          align_items = "center",
          gap = CARD_SPACING,
        },
      },

      -- Buttons section
      Layout.new {
        name = "TrophyButtons",
        animation_duration = 0,
        box = Box.new(Position.zero(), w, 100),
        els = {
          self._press_your_luck_button,
          self._skip_button,
        },
        flex = {
          direction = "row",
          justify_content = "center",
          align_items = "center",
          gap = 40,
        },
      },
    },
    flex = {
      direction = "column",
      justify_content = "center",
      align_items = "center",
      gap = 40,
    },
  }

  self:append_child(main_layout)
end

--- Handle card selection
---@param idx number
---@param card vibes.Card
---@return UIAction
function PressYourLuckUI:_select_card(idx, card)
  self._selected = card
  self._confirm_button:set_interactable(true)

  -- Update selection state for all cards
  for card_idx, card_el in ipairs(self._card_elements) do
    if card_idx == idx then
      card_el:set_selected(true)
    else
      card_el:set_selected(false)
    end
  end

  return UIAction.HANDLED
end

function PressYourLuckUI:_render() end

function PressYourLuckUI:__tostring() return "PressYourLuckUI" end

return PressYourLuckUI
