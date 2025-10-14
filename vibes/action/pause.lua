local Action = require "vibes.action"
local ButtonElement = require "ui.elements.button"
local Overlay = require "ui.components.elements.overlay"
local Range = require "ui.components.inputs.range"
local Save = require "vibes.systems.save"
local Text = require "ui.components.text"
local Toggle = require "ui.components.inputs.toggle"

---@class actions.Pause.Opts : actions.BaseOpts

---@class actions.Pause : vibes.Action
---@field new fun(opts: actions.Pause.Opts): actions.ClickOnTower
---@field init fun(self: actions.Pause, opts: actions.ClickOnTower.Opts)
---@field mode vibes.GameMode
---@field overlay ui.element.Overlay
---@field menus layout.Layout[]
---@field center vibes.Position
---@field _navigate_to ModeName
local Pause = class("actions.ClickOnTower", { super = Action })

local MENU_W = 490

local MENU_H = 340
local PADDING = 30
local MENU_BTN_W = MENU_W - (PADDING * 2)
local MENU_BTN_H = 80
local MENU_BTN_LABEL_H = 10

---@param opts actions.Pause.Opts
function Pause:init(opts)
  validate(opts, { tower = "vibes.Tower" })

  Action.init(self, {
    name = "Pause",
    on_cancel = opts.on_cancel,
    on_success = opts.on_success,
    on_complete = opts.on_complete,
  })

  self.center = Position.new(
    (Config.window_size.width / 2) - (MENU_W / 2),
    (Config.window_size.height / 2) - (MENU_H / 2)
  )

  self.mode = State:get_mode() --[[@as vibes.GameMode]]
  self.menus = {}
  self.overlay = Overlay.new {
    background = Colors.black:opacity(0.8),
    on_close = function() self:resolve(ActionResult.COMPLETE) end,
    z = Z.OVERLAY,
  }

  State.is_paused = true
end

function Pause:start()
  UI.root:append_child(self.overlay)
  self.overlay:open(function() end)

  UI.root:append_child(self:_init_main_menu())

  return ActionResult.ACTIVE
end

function Pause:update() return ActionResult.ACTIVE end

function Pause:finish()
  local current_menu = self.menus[#self.menus]
  current_menu:set_interactable(false)
  current_menu:animate_style({ opacity = 0 }, { duration = 0.1 })

  self.overlay:close(function()
    UI.root:remove_child(self.menus[#self.menus])

    for index in ipairs(self.menus) do
      table.remove(self.menus, index)
    end

    UI.root:remove_child(self.overlay)

    if self._navigate_to then
      State.mode = self._navigate_to
    end

    State.is_paused = false
  end)
end

function Pause:_init_main_menu()
  local exit_label = "Save and Exit"

  if State.mode == ModeName.MAIN_MENU then
    exit_label = "Quit Game"
  end

  local menu = Layout.new {
    name = "Pause(MainMenu)",
    box = Box.new(self.center:clone(), MENU_W, MENU_H),
    animation_duration = 0,
    els = {
      ButtonElement.new {
        box = Box.new(Position.zero(), MENU_BTN_W, MENU_BTN_H),
        label = "Settings",
        on_click = function()
          UI.root:remove_child(self.menus[#self.menus])
          UI.root:append_child(self:_init_settigns_menu())
        end,
      },
      -- ButtonElement.new {
      --   box = Box.new(Position.zero(), MENU_BTN_W, MENU_BTN_H),
      --   label = "Gameplay Settings",
      --   on_click = function() end,
      -- },
      ButtonElement.new {
        box = Box.new(Position.zero(), MENU_BTN_W, MENU_BTN_H),
        label = exit_label,
        on_click = function()
          if State.mode == ModeName.GAME then
            Save.SaveGame()
            State.levels:reset_level_state() -- Reset everything because I'm paranoid
            self._navigate_to = ModeName.MAIN_MENU
            self:resolve(ActionResult.COMPLETE)
          elseif State.mode == ModeName.MAIN_MENU then
            -- Quit immediately without resolving - game is shutting down
            -- Don't trigger any animations or cleanup that could process events
            love.event.quit()
            return  -- Exit immediately, don't resolve or do anything else
          else
            self._navigate_to = ModeName.MAIN_MENU
            self:resolve(ActionResult.COMPLETE)
          end
        end,
      },
    },
    flex = {
      align_items = "center",
      justify_content = "center",
      direction = "column",
      gap = PADDING,
    },
    z = Z.OVERLAY + 10,
    background = Colors.black:opacity(0.9),
    rounded = 20,
  }
  table.insert(self.menus, menu)
  return menu
end

function Pause:_init_settigns_menu()
  local window_setting = Toggle.new {
    position = Position.zero(),
    on_click = function(toggle)
      local value = toggle.value.value
      Config:set_window_settings(value)
    end,
    options = {
      { label = "Windowed", value = "windowed" },
      { label = "Windowed Borderless", value = "windowed_borderless" },
      { label = "Fullscreen", value = "fullscreen" },
    },
    default_value = Config.window_size.mode,
    clickable = true,
  }

  local SETTING_H = 590
  local SETTING_BTN_H = 40
  local center = Position.new(
    (Config.window_size.width / 2) - (MENU_W / 2),
    (Config.window_size.height / 2) - (SETTING_H / 2)
  )

  local menu = Layout.new {
    name = "Pause(MainMenu)",
    animation_duration = 0,
    box = Box.new(center, MENU_W, SETTING_H),
    els = {
      Text.new {
        "Window Setting",
        box = Box.new(Position.zero(), MENU_BTN_W, MENU_BTN_LABEL_H),
        font = Asset.fonts.insignia_20,
        color = { 1, 1, 1, 1 },
      },
      window_setting,
      Text.new {
        "Master Volume",
        box = Box.new(Position.zero(), MENU_BTN_W, MENU_BTN_LABEL_H),
        font = Asset.fonts.insignia_20,
        color = { 1, 1, 1, 1 },
      },
      Range.new {
        box = Box.new(Position.zero(), MENU_BTN_W, SETTING_BTN_H),
        value = 0,
        max_value = 10,
        increment_by = 1,
        on_click = function(range)
          love.audio.setVolume(self:_to_float(range.value))
          Config.sounds.master = range:_to_float()
          SoundManager:update_all_volumes()
        end,
        clickable = true,
      },
      Text.new {
        "Music Volume",
        box = Box.new(Position.zero(), MENU_BTN_W, MENU_BTN_LABEL_H),
        font = Asset.fonts.insignia_20,
        color = { 1, 1, 1, 1 },
      },
      Range.new {
        box = Box.new(Position.zero(), MENU_BTN_W, SETTING_BTN_H),
        value = 0,
        max_value = 10,
        increment_by = 1,
        on_click = function(range)
          Config.sounds.music_volume = range:_to_float()
          SoundManager:update_all_volumes()
        end,
        clickable = true,
      },
      Text.new {
        "Sound FX Volume",
        box = Box.new(Position.zero(), MENU_BTN_W, MENU_BTN_LABEL_H),
        font = Asset.fonts.insignia_20,
        color = { 1, 1, 1, 1 },
      },
      Range.new {
        box = Box.new(Position.zero(), MENU_BTN_W, SETTING_BTN_H),
        value = 0,
        max_value = 10,
        increment_by = 1,
        on_click = function(range)
          Config.sounds.sfx_volume = range:_to_float()
          SoundManager:update_all_volumes()
        end,
        clickable = true,
      },
      ButtonElement.new {
        box = Box.new(Position.zero(), MENU_BTN_W, MENU_BTN_H),
        label = "Go back",
        on_click = function()
          UI.root:remove_child(table.remove(self.menus, #self.menus))
          UI.root:append_child(self.menus[#self.menus])
        end,
      },
    },
    flex = {
      align_items = "center",
      justify_content = "center",
      direction = "column",
      gap = PADDING,
    },
    z = Z.OVERLAY + 10,
    background = Colors.black:opacity(0.9),
    rounded = 20,
  }
  table.insert(self.menus, menu)
  return menu
end
function Pause:_to_float(value) return (value - 1) / 9 end
function Pause:_to_range(value)
  value = math.max(0, math.min(0, value))
  return value * 9 + 1
end
return Pause
