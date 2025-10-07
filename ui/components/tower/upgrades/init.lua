local ButtonElement = require "ui.elements.button"
local PrimaryButton = require "ui.components.inputs.primary-button"
local Text = require "ui.components.text"
local TowerUpgradeButton = require "ui.components.tower.upgrades.button"
local DEFAULT_W = Config.window_size.width
local DEFAULT_H = 600

---@class (exact) components.TowerUpgrades.Opts
---@field box? ui.components.Box
---@field upgrades tower.UpgradeOption[]
---@field on_confirm fun(op:tower.UpgradeOption)
---@field on_skip fun()

---@class (exact) components.TowerUpgrades : Element
---@field new fun(opts: components.TowerUpgrades.Opts): components.TowerUpgrades
---@field _upgrades tower.UpgradeOption[]
---@field _selected_upgrade tower.UpgradeOption?
---@field _on_confirm fun(op:tower.UpgradeOption)
---@field _on_skip fun()
local TowerUpgrades = class("components.TowerUpgrade", { super = Element })

function TowerUpgrades:init(opts)
  validate(opts, {
    upgrades = "tower.UpgradeOption[]",
    box = "ui.components.Box?",
    on_confirm = "function",
    on_skip = "function",
  })

  self._upgrades = opts.upgrades
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

  Element.init(self, box)
  self:set_z(Z.OVERLAY)

  self:_setup_layout()
end

function TowerUpgrades:_render() end

function TowerUpgrades:_setup_layout()
  local _, _, w, h = self:get_geo()

  local confirm_button = PrimaryButton.new {
    on_click = function(_)
      if not self._selected_upgrade then
        UI:create_user_message "No upgrade was selected!"
        return
      end

      self._on_confirm(self._selected_upgrade)

      self._selected_upgrade = nil
    end,
    clickable = false,
  }

  local buttons = {}
  local buttons_w = w * 0.50

  for idx, op in ipairs(self._upgrades) do
    table.insert(
      buttons,
      TowerUpgradeButton.new {
        box = Box.new(Position.zero(), buttons_w, 70),
        upgrade = op,
        callback = function()
          self._selected_upgrade = op
          EventBus:emit_tower_upgrade_selected { upgrade = op }
          confirm_button:set_interactable(true)
          for btn_id, btn in ipairs(buttons) do
            if btn_id ~= idx then
              btn:set_selected(false)
            end
          end
        end,
      }
    )
  end

  local layout = Layout.new {
    name = "TowerUpgrades(Layout)",
    box = Box.new(Position.zero(), w, h),
    els = {
      Layout.col {
        box = Box.new(Position.zero(), w * 0.25, h),
        els = {},
      },
      Layout.col {
        box = Box.new(Position.zero(), buttons_w, h),
        els = {
          Text.new {
            "Level Gained!",
            text_align = "center",
            color = Colors.white:get(),
            font = Asset.fonts.typography.h1,
            box = Box.new(Position.zero(), buttons_w, 100),
          },
          Text.new {
            "Choose a permanent upgrade to apply to this tower",
            text_align = "center",
            color = Colors.white:get(),
            font = Asset.fonts.typography.paragraph_md,
            box = Box.new(Position.zero(), buttons_w, 60),
          },
          Layout.new {
            name = "TowerUpgrades(Buttons)",
            box = Box.new(Position.zero(), buttons_w, h - 260),
            els = buttons,
            flex = {
              direction = "column",
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
        box = Box.new(Position.zero(), w * 0.25, h),
        els = {
          Layout.rectangle { w = 250, h = 50 },
          confirm_button,
          ButtonElement.new {
            box = Box.new(Position.zero(), 250, 50),
            label = "Skip",
            on_click = function() self._on_skip() end,
          },
          Layout.rectangle { w = 250, h = 50 },
        },
        flex = {
          justify_content = "end",
          align_items = "center",
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

  self:append_child(layout)
end

return TowerUpgrades
