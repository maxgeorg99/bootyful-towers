local BoxUI = require "ui.elements.box"
local Container = require "ui.components.container"
local DynamicDialog = require "ui.elements.dynamic-dialog"
local EvolutionOption = require "vibes.tower.meta.tower-evolution-option"
local GrassGenerator = require "ui.components.grass-generator"
local Image = require "ui.components.img"
local Overlay = require "ui.components.elements.overlay"
local PlaceBox = require "ui.components.place_box"
local Text = require "ui.components.text"
local TileOverdrawnElement = require "vibes.data.TilesetOverdrawnElement"
local Tower = require "vibes.tower.base"
local TowerPlacementUtils = require "ui.components.tower_placement_utils"
local evolution_width = 500
local padding = 10
local title_height = 30

---@class tower.EvolutionMenu.EvolutionItemOpts
---@field tower vibes.Tower
---@field upgrade tower.EvolutionOption
---@field on_click fun()

---@param opts tower.EvolutionMenu.EvolutionItemOpts
local function create_evolution_item(opts)
  validate(opts, {
    tower = Tower,
    upgrade = EvolutionOption,
    on_click = "function",
  })

  local texture = opts.upgrade.texture
  local text = opts.upgrade.title
  local description = opts.upgrade.description

  local tile_config = Config.ui.tile_overdrawn
  local cell_size = Config.grid.cell_size
  local grass_offset = tile_config.grass_height_max * tile_config.scale
  local scale = Config.tower.scale
  local img_container_width = cell_size
  local img_width = texture:getWidth() * scale
  local img_height = texture:getHeight() * scale
  local evolution_height = cell_size * 2
  local description_width = evolution_width - img_container_width - padding
  local description_height = evolution_height - title_height

  local tower_preview_container = Container.new {
    name = "EvolutionTowerPreviewContainer",
    box = Box.new(Position.zero(), img_container_width, evolution_height),
  }
  local img = Image.new(texture, scale, scale)
  tower_preview_container:append_child(img)

  local image_x = (cell_size - img_width) / 2
  local image_y = evolution_height - img_height - grass_offset * 3

  img:set_pos(Position.new(image_x, image_y))

  -- Create hints display
  local hints = {}
  local hints_count = #opts.upgrade.hints
  if hints_count > 0 then
    local hint_w = description_width / hints_count

    for _, h in ipairs(opts.upgrade.hints) do
      local field_icon = TowerStatFieldIcon[h.field]
      local icon = Asset.icons[IconType.UP_ARROW]
      local hint_color = Colors.green

      if h.hint == UpgradeHint.BAD then
        icon = Asset.icons[IconType.DOWN_ARROW]
        hint_color = Colors.red
      end

      local hint = Text.new {
        function()
          return {
            { icon = Asset.icons[field_icon], color = Colors.white },
            {
              text = string.format("%s ", TowerStatFieldLabel[h.field]),
              color = Colors.white,
            },
            { icon = icon, color = hint_color },
          }
        end,
        box = Box.new(Position.zero(), hint_w, 20),
        text_align = "left",
        font = Asset.fonts.typography.paragraph_sm,
      }

      table.insert(hints, hint)
    end
  end

  local description_els = {
    Layout.rectangle { h = padding, w = description_width },
    Text.new {
      text,
      box = Box.new(Position.zero(), description_width, title_height),
      font = Asset.fonts.typography.h2,
      color = Colors.white,
      align = "left",
    },
    Text.new {
      description,
      box = Box.new(
        Position.zero(),
        description_width,
        description_height - (hints_count > 0 and 25 or 0)
      ),
      font = Asset.fonts.typography.paragraph_md,
      color = Colors.white,
      align = "left",
    },
  }

  -- Add hints if they exist
  if hints_count > 0 then
    table.insert(
      description_els,
      Layout.row {
        name = "EvolutionHintsRow",
        box = Box.new(Position.zero(), description_width, 20),
        flex = {
          direction = "row",
          justify_content = "start",
          align_items = "center",
          gap = 5,
        },
        els = hints,
      }
    )
  end

  local description_layout = Layout.col {
    name = "EvolutionDescriptionLayout",
    box = Box.new(Position.zero(), description_width, evolution_height),
    flex = {
      align_items = "start",
      justify_content = "start",
    },
    els = description_els,
  }

  local upgrade_layout = Layout.row {
    name = "EvolutionUpgradeLayout",
    box = Box.new(Position.zero(), evolution_width, evolution_height),
    z = Z.EVOLUTION_MENU_TEXT,
    flex = {
      align_items = "start",
      justify_content = "start",
    },
    els = {
      tower_preview_container,
      Layout.rectangle { w = padding * 2, h = padding },
      description_layout,
    },
  }

  local cont = Container.new {
    name = "EvolutionMenu",
    box = Box.new(Position.zero(), evolution_width, evolution_height),
    z = Z.EVOLUTION_BASE_MENU,
    interactable = true,
    on_click = opts.on_click,
  }

  local grass_generator = GrassGenerator.new {
    level_index = 3,
  }

  local grass_tile = TileOverdrawnElement.new {
    cell = grass_generator:cell(0, 3),
    position = Position.new(
      0,
      evolution_height - Config.grid.cell_size - grass_offset
    ),
  }

  grass_tile:set_z(Z.EVOLUTION_MENU_GRASS)
  cont:append_child(grass_tile)

  img:set_z(Z.EVOLUTION_MENU_TOWER)
  cont:append_child(tower_preview_container)
  cont:append_child(upgrade_layout)

  local button = Container.new {
    box = Box.new(Position.zero(), evolution_width, evolution_height),
    background = { 0.1, 0.1, 0.1, 1 },
    hover_background = { 0.2, 0.2, 0.2, 1 },
    on_click = opts.on_click,
  }

  button:append_child(cont)

  local box = DynamicDialog.new {
    name = "EvolutionMenuButton",
    kind = "empty",
    element = button,
  }

  return box
end

---@class (exact) tower.EvolutionMenu.Opts : Element.Opts
---@field evolutions tower.EvolutionOption[]
---@field on_select fun(evolution: tower.EvolutionOption)
---@field tower vibes.Tower

---@class (exact) tower.EvolutionMenu: Element
---@field evolutions tower.EvolutionOption[]
---@field on_select fun(evolution: tower.EvolutionOption)
---@field new fun(opts: tower.EvolutionMenu.Opts): tower.EvolutionMenu
---@field init fun(self: tower.EvolutionMenu, options:tower.EvolutionMenu.Opts)
---@field tower vibes.Tower
local EvolutionMenu = class("components.EvolutionMenu", { super = Element })

---@param opts tower.EvolutionMenu.Opts
function EvolutionMenu:init(opts)
  validate(opts, {
    evolutions = "table",
    on_select = "function",
    tower = Tower,
  })

  local upgrade_height = title_height + padding + Config.grid.cell_size * 2
  local box =
    Box.new(Position.zero(), evolution_width, upgrade_height * 3 + padding * 2)
  Element.init(self, box, opts)

  self.evolutions = opts.evolutions
  self.on_select = opts.on_select
  self.tower = opts.tower

  local tower_box = TowerPlacementUtils.tower_to_ui_box(self.tower)
  box = PlaceBox.position(box, tower_box, { priority = { "right", "left" } })

  local items = {}
  for _, evolution in ipairs(self.evolutions) do
    local item = create_evolution_item {
      tower = self.tower,
      upgrade = evolution,
      on_click = function() self.on_select(evolution) end,
    }
    table.insert(items, item)
  end

  local layout = Layout.col {
    name = "EvolutionMenuLayout",
    box = box,
    flex = {
      align_items = "start",
      justify_content = "start",
      gap = padding,
    },
    z = Z.EVOLUTION_BASE_MENU,
    els = items,
  }

  self:append_child(layout)

  local overlay = Overlay.new {
    name = "EvolutionMenuOverlay",
    box = Box.new(
      Position.zero(),
      Config.window_size.width,
      Config.window_size.height
    ),
    z = Z.EVOLUTION_BASE_OVERLAY,
    background_color = { 0, 0, 0, 0.6 },
    can_close = false,
  }

  self:append_child(overlay)

  local tower = Image.new(self.tower.texture, 2, 2)
  tower:set_pos(
    TowerPlacementUtils.tower_offset(tower_box.position, self.tower.cell)
  )
  tower:set_z(Z.EVOLUTION_MENU_TOWER)
  self:append_child(tower)
end

function EvolutionMenu:_render() end

return EvolutionMenu
