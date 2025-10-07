local PressYourLuckUI = require "ui.components.trophy.press-your-luck"
local TrophyOverlay = require "ui.components.trophy.overlay"
local TrophyText = require "ui.components.trophy.text"

local wave_to_card_rarity = {
  [3] = Rarity.COMMON,
  [4] = Rarity.UNCOMMON,
  [5] = Rarity.RARE,
  [6] = nil,
  [7] = Rarity.EPIC,
  [8] = Rarity.LEGENDARY,
}
local GEAR_WAVE = 6

local actions = {
  ---@param trophy components.trophy.UI
  function(trophy)
    trophy:append_child(TrophyOverlay.new {})
    Timer.oneshot(250, function() trophy:next_action() end)
  end,
  function(trophy)
    local load_time = trophy:current_wave_is_gear() and 1000 or 500
    local placement = trophy:current_wave_is_gear() and "center" or "start"
    trophy.victory_text = TrophyText.new {
      text = "Victory!",
      placement = placement,
    }
    trophy:append_child(trophy.victory_text)
    Timer.oneshot(load_time, function() trophy:next_action() end)
  end,
  function(trophy)
    if trophy:current_wave_is_gear() then
      trophy:_gear_selection()
    else
      trophy:_card_selection()
    end
  end,
  function(trophy)
    trophy.trophy_ui:animate_to_absolute_position(
      Position.new(Config.window_size.width + 200, 0)
    )
    trophy.victory_text:animate_to_absolute_position(
      Position.new(Config.window_size.width + 200, 0)
    )

    Timer.oneshot(200, function() trophy:next_action() end)

    Timer.oneshot(800, function()
      UI.root:remove_child(trophy.trophy_ui)
      UI.root:remove_child(trophy.victory_text)
      trophy.trophy_ui = nil
      trophy.victory_text = nil
    end)
  end,
  function(trophy)
    if trophy:_all_waves_completed() then
      trophy:complete_all_actions()
      return
    else
      trophy:_press_your_luck()
      trophy.press_your_luck_text = TrophyText.new { text = "Press your luck!" }
      trophy:append_child(trophy.press_your_luck_text)
    end
  end,
  function(trophy)
    trophy.press_your_luck_ui:animate_to_absolute_position(
      Position.new(Config.window_size.width + 200, 0)
    )
    trophy.press_your_luck_text:animate_to_absolute_position(
      Position.new(Config.window_size.width + 200, 0)
    )
    trophy.press_your_luck_ui = nil
    trophy.press_your_luck_text = nil

    Timer.oneshot(200, function() trophy:next_action() end)
  end,
}

---@class components.trophy.UI.Opts
---@field on_complete? fun(): nil
---@field on_choose_shop? fun(): nil
---@field current_completed_wave number

---@class (exact) components.trophy.UI : Element
---@field new fun(opts: components.trophy.UI.Opts): components.trophy.UI
---@field init fun(self: components.trophy.UI, opts: components.trophy.UI.Opts)
---@field on_complete? fun(): nil
---@field on_choose_shop? fun(): nil
---@field current_completed_wave number
---@field next_wave number
---@field rarity Rarity
---@field next_rarity Rarity
---@field overlay Container
---@field action_index number
---@field trophy_ui Element?
---@field press_your_luck_ui Element?
---@field press_your_luck_text Element?
---@field gear_trophy_ui Element?
local TrophyUI = class("components.trophy.UI", { super = Element })

---@param opts components.trophy.UI.Opts
function TrophyUI:init(opts)
  validate(opts, {
    on_complete = "function?",
  })
  self.action_index = 1

  -- Initialize as a minimal element that just holds the delegate
  local box = Box.new(Position.new(0, 0), 0, 0)
  Element.init(self, box, {
    z = Z.TROPHY_SELECTION_OVERLAY,
    interactable = false,
  })

  local next_wave = opts.current_completed_wave + 1
  self.name = "TrophyUI"
  self.on_complete = opts.on_complete
  self.on_choose_shop = opts.on_choose_shop
  self.current_completed_wave = opts.current_completed_wave
  self.rarity = wave_to_card_rarity[opts.current_completed_wave]
  self.next_rarity = wave_to_card_rarity[next_wave]
  self:next_action()
end

function TrophyUI:_update() end

function TrophyUI:_render() end

function TrophyUI:next_action()
  if self.action_index > #actions then
    UI.root:remove_child(self)
    self.on_complete()
    return
  end
  actions[self.action_index](self)
  self.action_index = self.action_index + 1
end

function TrophyUI:complete_all_actions()
  self.action_index = #actions + 1
  self:next_action()
end

function TrophyUI:_card_selection()
  local CardTrophyUI = require "ui.components.trophy.cards-trophy"

  local rarity = nil
  if self.rarity ~= Rarity.COMMON then
    rarity = self.rarity
  end
  local ui = CardTrophyUI.new {
    on_complete = function() self:next_action() end,
    rarity = rarity,
    is_trophy = true,
  }

  self.trophy_ui = ui
  UI.root:append_child(ui)
end

function TrophyUI:_press_your_luck()
  if self.rarity ~= Rarity.LEGENDARY then
    self.press_your_luck_ui = PressYourLuckUI.new {
      rarity = self.next_rarity or Rarity.RARE,
      on_choose_level = function()
        self:next_action()
        self.on_complete()
      end,
      on_choose_shop = function()
        self:next_action()
        self.on_choose_shop()
      end,
    }
    UI.root:append_child(self.press_your_luck_ui)
  end
end

function TrophyUI:_all_waves_completed()
  return self.current_completed_wave == Config.ui.level.wave_count
end

function TrophyUI:_gear_selection()
  local GearTrophyUI = require "ui.components.trophy.gear-trophy"
  self.trophy_ui = GearTrophyUI.new {
    on_complete = function() self:next_action() end,
  }
  UI.root:append_child(self.trophy_ui)
end

function TrophyUI:next_wave_is_gear() return self.next_wave == GEAR_WAVE end

function TrophyUI:current_wave_is_gear()
  return self.current_completed_wave == GEAR_WAVE
end

return TrophyUI
