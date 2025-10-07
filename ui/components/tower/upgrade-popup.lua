local PlaceBox = require "ui.components.place_box"
local Tower = require "vibes.tower.base"
local TowerPlacementUtils = require "ui.components.tower_placement_utils"
local TowerUpgradeButton = require "ui.elements.upgrade-button"
local text = require "utils.text"

---@class (exact) ui.components.UpgradePopup.Opts
---@field upgrades tower.UpgradeOption[]
---@field on_confirm fun(op: tower.UpgradeOption|tower.EvolutionOption)
---@field tower vibes.Tower

---@class (exact) ui.components.UpgradePopup : Element
---@field new fun(opts: ui.components.UpgradePopup.Opts): ui.components.UpgradePopup
---@field init fun(self: ui.components.UpgradePopup, opts: ui.components.UpgradePopup.Opts)
---@field tower vibes.Tower
---@field _on_confirm fun(op: tower.UpgradeOption|tower.EvolutionOption)
---@field _upgrades tower.UpgradeOption[]
---@field t number
---@field direction_arrow ui.components.Img
---@field hover_tooltip ui.components.Tooltip
local UpgradePopup = class("components.UpgradePopup", { super = Element })

function UpgradePopup:init(opts)
  validate(opts, {
    upgrades = "table",
    on_confirm = "function",
    tower = Tower,
  })

  self.tower = opts.tower
  self._on_confirm = opts.on_confirm
  self._upgrades = opts.upgrades

  local tower_box = TowerPlacementUtils.tower_to_ui_box(self.tower)

  local initial_box = Box.new(Position.new(0, 0), 0, 50)

  initial_box, _ = PlaceBox.position(initial_box, tower_box, {
    priority = { "top", "bottom" },
    padding = 8,
  })

  Element.init(self, initial_box, { z = Z.OVERLAY })

  local layout = Layout.new {
    name = "TowerUpgradeButtons",
    box = Box.new(Position.zero(), 0, 0),
    z = Z.UPGRADE_MENU,
    flex = {
      justify_content = "center",
      align_items = "center",
      direction = "row",
      gap = 0,
    },
  }

  for _, upgrade in ipairs(opts.upgrades) do
    local op = upgrade.operations[1]

    local value = text.format_number(op.operation.value)

    if op.field == TowerStatField.CRITICAL then
      value = text.format_number(math.floor(op.operation.value * 100)) .. "%"
    end

    local upgrade_btn = TowerUpgradeButton.new {
      position = Position.zero(),
      icon_type = TowerStatFieldIcon[op.field],
      rarity = upgrade.rarity,
      value = function() return value end,
      on_click = function() self._on_confirm(upgrade) end,
      description = upgrade.name,
    }

    layout:set_width(layout:get_width() + upgrade_btn:get_width())
    self:set_width(self:get_width() + upgrade_btn:get_width())

    layout:append_child(upgrade_btn)
  end

  self:set_x(self:get_x() - self:get_width() / 2)

  -- Check if the popup goes outside screen bounds and adjust if necessary
  self:_ensure_within_bounds()

  -- If we have many upgrades, consider stacking them vertically instead of horizontally
  self:append_child(layout)
end

--- Ensure the popup stays within screen bounds
function UpgradePopup:_ensure_within_bounds()
  local screen_width = Config.window_size.width
  local screen_height = Config.window_size.height
  local popup_x, popup_y, popup_w, popup_h = self:get_geo()

  -- Check horizontal bounds
  if popup_x < 0 then
    self:set_x(10) -- Small margin from left edge
  elseif popup_x + popup_w > screen_width then
    self:set_x(screen_width - popup_w - 10) -- Small margin from right edge
  end

  -- Check vertical bounds
  if popup_y < 0 then
    -- Popup goes off the top edge, shift it down
    self:set_y(10) -- Small margin from top edge
  elseif popup_y + popup_h > screen_height then
    -- Popup goes off the bottom edge, shift it up
    self:set_y(screen_height - popup_h - 10) -- Small margin from bottom edge
  end
end

function UpgradePopup:_render() end

return UpgradePopup
