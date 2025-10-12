local ButtonElement = require "ui.elements.button"
local ChatacterButton = require "ui.components.character.selection.button"
local Details = require "ui.components.character.selection.details"
local Save = require "vibes.systems.save"
local Text = require "ui.components.text"
local TextInputPopUp = require "ui.components.text-input-popup"

---@class components.CharacterSelectionView.Opts

---@class components.CharacterSelectionView: Element
---@field new fun(opts:components.CharacterSelectionView.Opts)
---@field init fun(self:components.CharacterSelectionView, opts:components.CharacterSelectionView.Opts)
---@field characters vibes.Character[]
---@field current_character CharacterKind
---@field layout Element
---@field details_layout Element
---@field details components.CharacterSelectionDetails[]
---@field buttons components.CharacterSelectionButton[]
---@field action_button elements.Button
---@field seed_input_popup ui.components.TextInputPopUp
local CharacterSelectionView =
  class("components.CharacterSelectionView", { super = Element })

function CharacterSelectionView:init(opts)
  print "[DEBUG] CharacterSelectionView:init() called"
  validate(opts, {
    characters = "vibes.Character[]",
  })

  local box = Box.fullscreen()
  Element.init(self, box)
  self:set_interactable(true)

  self.current_character = CharacterKind.BLACKSMITH
  State.deck = State.characters[1].starter.deck
  State.player.gold = State.characters[1].starter.gold
  State.player.energy = State.characters[1].starter.energy

  State.player.health = Config.player.default_health

  local padding = 30
  local screen_w = Config.window_size.width
  local half_screen_w = screen_w / 2

  self.details = {}
  self.buttons = {}

  -- Start with blacksmith theme
  SoundManager:play_character_theme(CharacterKind.BLACKSMITH)

  local width = Config.window_size.width
  local half_width = Config.window_size.width / 2
  local height = Config.window_size.height
  local button_height = 100
  self.action_buttons = {}
  local width_multiplier = 0.32
  local padding_divsor = 3
  if not Save.PlayerHasSavedGame() then
    width_multiplier = 0.5
    padding_divsor = 2
  end

  -- Presets based on whether we show the `Continue` button
  local new_game_box = Box.new(
    Position.zero(),
    (half_width * width_multiplier) - (padding / padding_divsor),
    button_height
  )
  local continue_box = Box.new(
    Position.zero(),
    (half_width * width_multiplier) - (padding / padding_divsor),
    button_height
  )
  local set_seed_box = Box.new(
    Position.zero(),
    (half_width * width_multiplier) - (padding / padding_divsor),
    button_height
  )

  local continue_botton = ButtonElement.new {
    box = continue_box,
    label = "Continue",
    on_click = function()
      Save.LoadGame()
      State.mode = ModeName.MAP
    end,
    interactable = true,
  }

  self.action_button = ButtonElement.new {
    box = new_game_box,
    label = "New Game",
    on_click = function()
      State.selected_character = self.current_character
      State.mode = ModeName.MAP
    end,
  }
  -- {
  --    ButtonElement.new {
  --      box = new_game_box,
  --      label = "New Game",
  --      on_click = function()
  --        State.selected_character = self.current_character
  --        State.mode = ModeName.MAP
  --      end,
  --    },
  -- ButtonElement.new {
  --   box = set_seed_box,
  --   label = "Set Seed",
  --   on_click = function()
  --     -- print "[DEBUG] Set Seed button clicked!"
  --     -- print("[DEBUG] seed_input_popup exists:", self.seed_input_popup ~= nil)
  --     -- print(
  --     --   "[DEBUG] seed_input_popup z-index:",
  --     --   self.seed_input_popup and self.seed_input_popup.z or "N/A"
  --     -- )
  --     -- print(
  --     --   "[DEBUG] seed_input_popup hidden:",
  --     --   self.seed_input_popup and self.seed_input_popup:get_hidden() or "N/A"
  --     -- )
  --     self.seed_input_popup:show()
  --     -- print(
  --     --   "[DEBUG] After show() - hidden:",
  --     --   self.seed_input_popup and self.seed_input_popup:get_hidden() or "N/A"
  --     -- )
  --   end,
  --   z = Z.MAX,
  -- },
  -- }

  if Save.PlayerHasSavedGame() then
    table.insert(self.action_buttons, 2, continue_botton)
  end

  local select_hero_label = Text.new {
    "Choose Your Hero",
    font = Asset.fonts.typography.h3,
    vertical_align = "center",
    color = Colors.white:get(),
    text_align = "left",
    box = Box.new(Position.zero(), half_screen_w, 50),
  }

  for idx, character in ipairs(State.characters) do
    table.insert(
      self.details,
      Details.new { character = character, color = { 1, 1, 1, 1 } }
    )

    table.insert(
      self.buttons,
      ChatacterButton.new {
        avatar = character.avatar,
        selected = idx == 1,
        callback = function()
          if character.kind == CharacterKind.FUTURIST then
            self.action_button.label = "Coming Soon"
            self.action_button:set_interactable(false)
            self.action_button:set_opacity(0.5)
          else
            self.action_button.label = "New Game"
            self.action_button:set_interactable(true)
            self.action_button:set_opacity(1)
          end

          self:_on_character_select(idx, character)
        end,
      }
    )
  end

  local character_buttons = Layout.row {
    box = Box.new(Position.zero(), half_screen_w, ((width / 2) / 3)),
    els = self.buttons,
    flex = { gap = 30 },
    animation_duration = 0,
  }

  local action_buttons = Layout.row {
    box = Box.new(Position.zero(), half_screen_w, button_height + padding),
    els = { self.action_button },
    flex = { gap = 30 },
    animation_duration = 0,
  }

  self.details_layout = Layout.row {
    box = Box.new(Position.zero(), width * 3, height),
    els = self.details,
    animation_duration = 0,
  }

  self:append_child(self.details_layout)

  local layout_height = select_hero_label:get_height()
    + character_buttons:get_height()
    + action_buttons:get_height()

  self.layout = Layout.col {
    box = Box.new(
      Position.new((width / 2) - 30, height - layout_height - 25),
      width / 2,
      layout_height
    ),
    flex = {},
    els = {
      select_hero_label,
      character_buttons,
      action_buttons,
    },
    animation_duration = 0,
  }
  self:append_child(self.layout)

  -- Create seed input popup
  print "[DEBUG] Creating seed_input_popup..."
  self.seed_input_popup = TextInputPopUp.new {
    pos_x = (Config.window_size.width - 400) / 2,
    pos_y = (Config.window_size.height - 300) / 2,
    width = 400,
    height = 300,
    prompt_text = "Enter Seed",
    placeholder_text = "Enter a number for the random seed",
    button_text = "Set Seed",
    on_enter = function(text) self:set_seed(text) end,
    validate_input = function(char) return tonumber(char) ~= nil or char == "-" end,
    character_limit = 10,
    font_color = { 1, 1, 1 },
    background_color = { 0.2, 0.2, 0.3 },
  }
  print("[DEBUG] seed_input_popup created, z-index:", self.seed_input_popup.z)

  -- Ensure the popup has a high z-index so it's visible above other elements
  self.seed_input_popup.z = 99999
  print("[DEBUG] seed_input_popup z-index set to:", self.seed_input_popup.z)

  -- Add the popup to the UI root so it can be rendered and interacted with
  print "[DEBUG] Adding seed_input_popup to UI.root..."
  UI.root:append_child(self.seed_input_popup)
  print "[DEBUG] seed_input_popup added to UI.root"

  -- Default focus index: 2 when Continue is present, else 1 (New Game)
  self.default_action_index = Save.PlayerHasSavedGame() and 2 or 1
  UI:focus_element(self.action_buttons[self.default_action_index])
end

---@param index number
---@param character vibes.Character
function CharacterSelectionView:_on_character_select(index, character)
  if self.current_character == character.kind then
    return
  end

  self.current_character = character.kind
  State.deck = character.starter.deck

  SoundManager:play_character_theme(character.kind)
  self.details_layout:animate_to_absolute_position(
    Position.new(-(Config.window_size.width * (index - 1)), 0),
    { duration = 0.2 }
  )

  for button_idx, button in ipairs(self.buttons) do
    if button_idx ~= index then
      button:set_selected(false)
    end
  end
end

function CharacterSelectionView:_render() end

---Set the random seed for the game
---@param seed_text string The seed value entered by the user
function CharacterSelectionView:set_seed(seed_text)
  print("[DEBUG] set_seed called with:", seed_text)
  local seed_num = tonumber(seed_text)
  if seed_num then
    math.randomseed(seed_num)
    Config.seed = seed_num
    print(string.format("[DEBUG] Seed set to: %d", seed_num))
    self.seed_input_popup:hide()
    print "[DEBUG] Popup hidden after setting seed"
  else
    print("[DEBUG] Invalid seed value entered:", seed_text)
  end
end

return CharacterSelectionView
