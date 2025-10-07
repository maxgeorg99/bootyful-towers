local Container = require "ui.components.container"
local ImageThreeSlice = require "ui.components.image-three-slice"
local PlaceBox = require "ui.components.place_box"
local StatUI = require "ui.components.stat"
local Tooltip = require "ui.components.tooltip"
local Tower = require "vibes.tower.base" -- Added for type hinting
local TowerPlacementUtils = require "ui.components.tower_placement_utils"

local PADDING = 12
local IMAGE_THREE_SLICE_ENDING_PADDING = 48
local ICON_SIZE = 42
local ICON_W_PADDING = 12
local ICON_H_PADDING = 24

---@class (exact) ui.components.TowerIconUpgradeMenu.Opts
---@field upgrades tower.UpgradeOption[]
---@field on_confirm fun(op: tower.UpgradeOption|tower.EvolutionOption)
---@field tower vibes.Tower

---@class (exact) ui.components.TowerIconUpgradeMenu : Element
---@field new fun(opts: ui.components.TowerIconUpgradeMenu.Opts): ui.components.TowerIconUpgradeMenu
---@field init fun(self: ui.components.TowerIconUpgradeMenu, opts: ui.components.TowerIconUpgradeMenu.Opts)
---@field tower vibes.Tower
---@field _on_confirm fun(op: tower.UpgradeOption|tower.EvolutionOption)
---@field _upgrades tower.UpgradeOption[]
---@field t number
---@field direction_arrow ui.components.Img
---@field hover_tooltip ui.components.Tooltip
local TowerIconUpgradeMenu =
  class("components.TowerIconUpgradeMenu", { super = Element })

---@param opts ui.components.TowerIconUpgradeMenu.Opts
function TowerIconUpgradeMenu:init(opts)
  validate(opts, {
    upgrades = "table",
    on_confirm = "function",
    tower = Tower,
  })

  -- Store tower reference
  self.tower = opts.tower
  self.t = 0
  self._on_confirm = opts.on_confirm

  local stat_width, stat_height =
    StatUI.calculate_geometry(ICON_SIZE, ICON_W_PADDING, ICON_H_PADDING)
  local upgrade_menu_height = (stat_height + PADDING) * #opts.upgrades
  local upgrade_menu_width = stat_width
  local container_width = upgrade_menu_width + PADDING * 2
  local container_height = upgrade_menu_height + PADDING * 2
  local initial_box =
    Box.new(Position.new(0, 0), stat_width, upgrade_menu_height)

  local tower_box = TowerPlacementUtils.tower_to_ui_box(self.tower)

  initial_box, _ = PlaceBox.position(initial_box, tower_box, {
    priority = { "top", "bottom" },
    padding = 10,
  })

  Element.init(self, initial_box, { interactable = true })
  self:set_z(Z.UPGRADE_MENU)

  local items = {}
  local background_colors = {}
  local full_width = upgrade_menu_width + PADDING * (#opts.upgrades - 1)

  for _, upgrade in ipairs(opts.upgrades) do
    table.insert(items, self:_create_upgrade_item(upgrade))
    local three_slice = ImageThreeSlice.new {
      box = Box.new(
        Position.zero(),
        full_width + IMAGE_THREE_SLICE_ENDING_PADDING,
        stat_height
      ),
      left_image = Asset.ui.tower_upgrade_menu_start,
      center_image = Asset.ui.tower_upgrade_menu_middle,
      right_image = Asset.ui.tower_upgrade_menu_end,
    }
    three_slice:set_z(Z.UPGRADE_MENU)
    table.insert(background_colors, three_slice)
  end

  local layout = Layout.col {
    name = "UpgradeItems",
    flex = {
      align_items = "start",
      justify_content = "start",
    },
    interactable = true,
    box = Box.new(Position.zero(), full_width, upgrade_menu_height),
    els = items,
  }
  layout:set_z(Z.UPGRADE_MENU_ITEMS)

  local layout_backgrounds = Layout.col {
    name = "UpgradeBackgrounds",
    box = Box.new(Position.zero(), full_width, upgrade_menu_height),
    flex = {
      align_items = "start",
      justify_content = "start",
    },
    els = background_colors,
  }
  layout_backgrounds:set_z(Z.UPGRADE_MENU)

  local container = Container.new {
    interactable = true,
    box = Box.new(Position.zero(), container_width, container_height),
  }

  container:append_child(layout_backgrounds)
  container:append_child(layout)
  container:set_z(Z.UPGRADE_MENU)
  self:append_child(container)
  self.name = "TowerIconUpgradeMenu"
end

function TowerIconUpgradeMenu:_on_hover_start()
  self.hover_tooltip = Tooltip.new("Lorem Ipsum", self, 300)
  self:append_child(self.hover_tooltip)
end

function TowerIconUpgradeMenu:_on_hover_end()
  if self.hover_tooltip then
    self:remove_child(self.hover_tooltip)
  end
end

---@param upgrade_item tower.UpgradeOption
function TowerIconUpgradeMenu:_create_upgrade_item(upgrade_item)
  assert(
    #upgrade_item.operations == 1,
    "tower upgrades must have exactly one operation"
  )
  local field = upgrade_item.operations[1].field
  return StatUI.new {
    z = Z.UPGRADE_MENU_STAT,
    interactable = true,
    field = field,
    upgrade = upgrade_item,
    stat = self.tower.stats_manager.result[field],
    icon_size = ICON_SIZE,
    icon_w_padding = ICON_W_PADDING,
    icon_h_padding = ICON_H_PADDING,
    on_select = function(stat) self._on_confirm(stat.upgrade) end,
  }
end

function TowerIconUpgradeMenu:_click() end

function TowerIconUpgradeMenu:_update(dt) self.t = self.t + dt end

function TowerIconUpgradeMenu:_render() end

function TowerIconUpgradeMenu:_mouse_enter() self:_on_hover_start() end

function TowerIconUpgradeMenu:_mouse_leave() end

function TowerIconUpgradeMenu:destroy()
  if self.parent then
    self.parent:remove_child(self)
  end
end

return TowerIconUpgradeMenu
