local Flux = require "vendor.flux"
local Text = require "ui.components.text"
local Tooltip = require "ui.components.tooltip"

local DEFAULT_W = Config.window_size.width * 0.90
local DEFAULT_H = 70

---@class (exact) components.TowerUpgradeButton.Opts
---@field box? ui.components.Box
---@field upgrade tower.UpgradeOption
---@field callback fun()

---@class (exact) components.TowerUpgradeButton : Element
---@field new fun(opts: components.TowerUpgradeButton.Opts): components.TowerUpgradeButton
---@field upgrade tower.UpgradeOption
---@field layout layout.Layout
---@field _tween Flux.Tween
---@field callback fun()
---@field actions {selected:boolean}
---@field set_selected fun(self:components.TowerUpgradeButton, bool:boolean)
---@field tooltip ui.components.Tooltip?
local TowerUpgradeButton = class("components.TowerUpgrade", { super = Element })

function TowerUpgradeButton:init(opts)
  validate(opts, {
    callback = "function",
    upgrade = "tower.TowerUpgradeOptions",
    box = "ui.components.Box?",
  })

  self.upgrade = opts.upgrade
  self.callback = opts.callback
  self.tooltip = nil

  self.actions = { selected = false }

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
    interactable = true,
  })

  local _, _, w, h = self:get_geo()

  local stat_upgrades = {}

  for idx, stat in ipairs(self.upgrade.operations) do
    local stat_label = stat.label
    local stat_value = stat.operation.value
    local op_label = stat.operation.label

    local upgrade = Text.new {
      "{icon:text}",
      function()
        return {
          {
            icon = Asset.icons[stat.icon],
            color = Colors.white:get(),
          },
          {
            text = string.format("%s %s %s", op_label, stat_value, stat_label),
          },
        }
      end,
      text_align = "center",
      color = Colors.white:get(),
      font = Asset.fonts.typography.paragraph_md,
      box = Box.new(Position.zero(), w / 3, h),
    }

    table.insert(stat_upgrades, upgrade)

    if idx ~= #self.upgrade.operations and #self.upgrade.operations ~= 1 then
      local and_layout = Layout.col {
        box = Box.new(Position.zero(), 40, h),
        els = {
          Layout.rectangle {
            w = 2,
            h = h * 0.20,
            background = Colors.white,
          },
          Text.new {
            "and",
            color = Colors.white:get(),
            font = Asset.fonts.typography.sub,
            box = Box.new(Position.zero(), 50, h * 0.20),
          },
          Layout.rectangle {
            w = 2,
            h = h * 0.20,
            background = Colors.white,
          },
        },
        { flex = 0 },
      }

      table.insert(stat_upgrades, and_layout)
    end
  end

  self.layout = Layout.new {
    name = "TowerUpgradeButton(Layout)",
    box = Box.new(Position.zero(), w, h),
    background = Colors.gray:opacity(1),
    rounded = 10,
    els = stat_upgrades,
    flex = {
      align_items = "center",
      justify_content = "space-evenly",
      direction = "row",
    },
  }

  self:append_child(self.layout)
end

---Get the description text for this upgrade option
---@return string
function TowerUpgradeButton:_get_description()
  if type(self.upgrade.description) == "function" then
    return self.upgrade.description()
  else
    return tostring(self.upgrade.description)
  end
end

function TowerUpgradeButton:_mouse_enter()
  self._tween =
    Flux.to(self.layout.background, 0.8, { unpack(Colors.burgundy) })
      :ease "quadinout"

  -- Create and show tooltip with upgrade description
  local description = self:_get_description()
  if description and description ~= "No description provided" then
    self.tooltip = Tooltip.new(description, self, 200, "NEAR_ELEMENT")
    UI.root:append_child(self.tooltip)
  end
end

function TowerUpgradeButton:_mouse_leave()
  if self._tween and not self.actions.selected then
    self._tween = Flux.to(self.layout.background, 0.8, { unpack(Colors.gray) })
      :ease "quadinout"
  end

  -- Hide and clean up tooltip
  if self.tooltip then
    if self.tooltip.parent then
      self.tooltip.parent:remove_child(self.tooltip)
    end
    self.tooltip = nil
  end
end

function TowerUpgradeButton:_update(dt) Flux.update(dt) end

function TowerUpgradeButton:set_selected(bool)
  self.actions.selected = bool

  local color = Colors.gray

  if bool then
    color = Colors.burgundy
    -- Hide tooltip when selected
    if self.tooltip then
      if self.tooltip.parent then
        self.tooltip.parent:remove_child(self.tooltip)
      end
      self.tooltip = nil
    end
  end

  self._tween = Flux.to(self.layout.background, 0.8, { unpack(color) })
    :ease "quadinout"
end

function TowerUpgradeButton:_click()
  self:set_selected(true)
  self.callback()
end

function TowerUpgradeButton:_render() end

return TowerUpgradeButton
