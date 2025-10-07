local Flux = require "vendor.flux"
local ScaledImage = require "ui.components.scaled-img"
local Text = require "ui.components.text"

local DEFAULT_W = 500
local DEFAULT_H = 385

---@class (exact) components.TowerEvolutionButton.Opts
---@field box? ui.components.Box
---@field evolution tower.EvolutionOption
---@field callback fun(evolution:tower.EvolutionOption)

---@class (exact) components.TowerEvolutionButton : Element
---@field new fun(opts: components.TowerEvolutionButton.Opts): components.TowerEvolutionButton
---@field callback fun(evolution:tower.EvolutionOption)
---@field evolution tower.EvolutionOption
---@field background vibes.Color
---@field layout layout.Layout
---@field _tween Flux.Tween
---@field actions {selected:boolean}
---@field set_selected fun(self:components.TowerEvolutionButton, bool:boolean)
local TowerEvolutionButton =
  class("components.TowerEvolutionButtin", { super = Element })

function TowerEvolutionButton:init(opts)
  validate(opts, {
    evolutions = "tower.EvolutionOption[]",
    box = "ui.components.Box?",
  })

  self.evolution = opts.evolution
  self.callback = opts.callback
  self.background = Colors.gray
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

  self:_set_layout()
end

function TowerEvolutionButton:_set_layout()
  local _, _, width, heigh = self:get_geo()

  local hints = {}

  local hint_w = width / #self.evolution.hints

  for _, h in ipairs(self.evolution.hints) do
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
          { icon = Asset.icons[field_icon], color = Colors.slate },
          {
            text = string.format("%s ", TowerStatFieldLabel[h.field]),
            color = Colors.slate,
          },
          { icon = icon, color = hint_color },
        }
      end,
      box = Box.new(Position.zero(), hint_w, 50),
      text_align = "center",
      font = Asset.fonts.typography.paragraph,
      padding = 30,
    }

    -- hint.debug = true

    table.insert(hints, hint)
  end

  self.layout = Layout.col {
    name = "TowerEvolution(Layout)",
    box = Box.new(Position.zero(), width, heigh),
    background = Colors.gray:get(),
    rounded = 15,
    els = {
      Layout.new {
        name = "",
        box = Box.new(Position.zero(), width, 150),
        els = {
          ScaledImage.new {
            texture = self.evolution.texture,
            box = Box.new(Position.zero(), 0, 250),
            scale_style = "fit",
          },
        },
        flex = {
          direction = "column",
          justify_content = "end",
          align_items = "center",
          gap = 0,
        },
      },
      Text.new {
        self.evolution.title,
        box = Box.new(Position.zero(), width, 60),
        font = Asset.fonts.typography.h3,
        vertical_align = "bottom",
      },
      Layout.col {
        box = Box.new(Position.zero(), width, 120),
        els = {
          Text.new {
            self.evolution.description,
            box = Box.new(Position.zero(), width * 0.90, 90),
            font = Asset.fonts.typography.paragraph_md,
            text_align = "center",
            vertical_align = "top",
          },
        },
      },
      Layout.new {
        name = "EvolutionButton(Hints)",
        box = Box.new(Position.zero(), width - 10, 50),
        background = Colors.white:opacity(0.5),
        rounded = 10,
        els = hints,
        flex = {
          direction = "row",
          justify_content = "space-evenly",
          align_items = "center",
        },
      },
    },
    flex = {
      direction = "column",
      justify_content = "start",
      align_items = "center",
      gap = 0,
    },
  }
  self:append_child(self.layout)
end

function TowerEvolutionButton:_render() end

function TowerEvolutionButton:_mouse_enter()
  self._tween =
    Flux.to(self.layout.background, 0.8, { unpack(Colors.burgundy) })
      :ease "quadinout"
end

function TowerEvolutionButton:_mouse_leave()
  if self._tween and not self.actions.selected then
    self._tween = Flux.to(self.layout.background, 0.8, { unpack(Colors.gray) })
      :ease "quadinout"
  end
end

function TowerEvolutionButton:_update(dt) Flux.update(dt) end

function TowerEvolutionButton:set_selected(bool)
  self.actions.selected = bool

  local color = Colors.gray

  if bool then
    color = Colors.burgundy
  end

  self._tween = Flux.to(self.layout.background, 0.8, { unpack(color) })
    :ease "quadinout"
end

function TowerEvolutionButton:_click()
  self:set_selected(true)
  self.callback(self.evolution)
end

return TowerEvolutionButton
