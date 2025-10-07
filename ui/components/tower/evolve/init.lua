local ButtonElement = require "ui.elements.button"
local PrimaryButton = require "ui.components.inputs.primary-button"
local Text = require "ui.components.text"
local TowerEvolutionButton = require "ui.components.tower.evolve.button"
local DEFAULT_W = Config.window_size.width
local DEFAULT_H = 650

---@class (exact) components.TowerEvolution.Opts
---@field box? ui.components.Box
---@field evolutions tower.EvolutionOption[]
---@field on_confirm fun(op:tower.EvolutionOption)
---@field on_skip fun()

---@class (exact) components.TowerEvolution : Element
---@field init fun(self:components.TowerEvolution, opts: components.TowerEvolution.Opts)
---@field new fun(opts: components.TowerEvolution.Opts): components.TowerEvolution
---@field evolutions tower.EvolutionOption[]
---@field reset fun(self:components.TowerEvolution)
---@field _layout layout.Layout
---@field _selected_evolution tower.EvolutionOption
---@field _on_confirm fun(op:tower.EvolutionOption)
---@field _on_skip fun()
local TowerEvolution = class("components.TowerEvolution", { super = Element })

function TowerEvolution:init(opts)
  validate(opts, {
    tower = "vibes.Tower",
    box = "ui.components.Box?",
  })

  self.evolutions = opts.evolutions
  self._on_confirm = opts.on_confirm
  self._on_skip = opts.on_skip

  local box = opts.box
    or Box.new(
      Position.new(
        (Config.window_size.width / 2) - (DEFAULT_W / 2),
        Config.window_size.height - DEFAULT_H
      ),
      DEFAULT_W,
      DEFAULT_H
    )

  Element.init(self, box, {
    interactable = false,
    z = Z.OVERLAY,
  })

  self:_set_layout()
end

function TowerEvolution:_set_layout()
  local _, _, w, h = self:get_geo()

  local confirm_button = PrimaryButton.new {
    on_click = function(_)
      if not self._selected_evolution then
        UI:create_user_message "No upgrade was selected!"
        return
      end

      self._on_confirm(self._selected_evolution)

      self._selected_evolution = nil
    end,
    clickable = false,
  }

  local buttons = {}
  local buttons_w = (w * 0.70)
  local button_w = (buttons_w / #self.evolutions)

  if #self.evolutions < 3 then
    button_w = 500
  end

  for idx, evolution in ipairs(self.evolutions) do
    table.insert(
      buttons,
      TowerEvolutionButton.new {
        box = Box.new(Position.zero(), button_w - 40, 385),
        evolution = evolution,
        callback = function()
          self._selected_evolution = evolution
          confirm_button:set_interactable(true)
          for btn_idx, btn in ipairs(buttons) do
            if btn_idx ~= idx then
              btn:set_selected(false)
            end
          end
        end,
      }
    )
  end

  local layout = Layout.new {
    name = "TowerEvolution(Layout)",
    box = Box.new(Position.zero(), w, h),
    els = {
      Layout.col {
        box = Box.new(Position.zero(), w * 0.15, h),
        els = {},
      },
      Layout.col {
        box = Box.new(Position.zero(), buttons_w, h),
        els = {
          Text.new {
            "Evolution Unlocked",
            text_align = "center",
            color = Colors.white:get(),
            font = Asset.fonts.typography.h1,
            box = Box.new(Position.zero(), buttons_w, 100),
          },
          Text.new {
            "Reconstruct this tower with new abilities",
            text_align = "center",
            color = Colors.white:get(),
            font = Asset.fonts.typography.paragraph_md,
            box = Box.new(Position.zero(), buttons_w, 60),
          },
          Layout.new {
            name = "TowerEvolution(Buttons)",
            box = Box.new(Position.zero(), buttons_w, 500),
            els = buttons,
            flex = {
              direction = "row",
              justify_content = "center",
              align_items = "center",
              gap = 20,
            },
          },
        },
        flex = {
          justify_content = "start",
          align_items = "center",
          direction = "row",
          gap = 0,
        },
      },
      Layout.col {
        box = Box.new(Position.zero(), w * 0.15, h),
        els = {
          Layout.rectangle { w = 250, h = 50 },
          confirm_button,
          ButtonElement.new {
            box = Box.new(Position.zero(), 150, 50),
            label = "Skip",
            on_click = function() self._on_skip() end,
          },
          Layout.rectangle { w = 250, h = 50 },
        },
        flex = {
          justify_content = "end",
          align_items = "start",
          direction = "row",
          gap = 30,
        },
      },
    },
    flex = {
      justify_content = "end",
      align_items = "end",
      direction = "row",
      gap = 0,
    },
  }
  -- layout.debug = true
  self:append_child(layout)
end

function TowerEvolution:_render() end

return TowerEvolution
