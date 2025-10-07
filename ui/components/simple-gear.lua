local Gear = require "gear"
local PlaceBox = require "ui.components.place_box"
local ScaledImage = require "ui.components.scaled-img"
local Text = require "ui.components.text"

local TitleBox = require "ui.elements.title-box"

local HOVER_TOOLTIP_WIDTH = 400
local HOVER_TOOLTIP_HEIGHT = 180

---@class ui.components.SimpleGear : Element
---@field new fun(opts: ui.components.SimpleGear.Opts): ui.components.SimpleGear
local SimpleGear = class("ui.components.SimpleGear", { super = Element })

---@class ui.components.SimpleGear.Opts
---@field box ui.components.Box
---@field gear gear.Gear
---@field z? number

function SimpleGear:init(opts)
  validate(opts, {
    box = Box,
    gear = Gear,
  })

  Element.init(self, opts.box, {
    z = opts.z,
  })

  self.gear = opts.gear
  self:append_child(ScaledImage.new {
    texture = self.gear.texture or Asset.sprites.card_back,
    box = Box.new(Position.zero(), opts.box.width, opts.box.height),
    scale_style = "fit",
  })

  self.hover_tooltip = TitleBox.new {
    title = self.gear.name,
    box = Box.new(Position.zero(), HOVER_TOOLTIP_WIDTH, HOVER_TOOLTIP_HEIGHT),
    kind = "filled",
    els = {
      Text.new {
        function() return self.gear.description end,
        box = Box.new(
          Position.zero(),
          HOVER_TOOLTIP_WIDTH * 0.8,
          HOVER_TOOLTIP_HEIGHT * 0.5
        ),
        font = Asset.fonts.typography.paragraph_md,
        color = Colors.white:get(),
        vertical_align = "center",
      },
    },
    z = Z.OVERLAY,
  }
  self.hover_tooltip:set_hidden(true)
end

function SimpleGear:get_scale() return 1 + self._props.entered * 0.1 end

function SimpleGear:_update()
  if self.targets.entered == 1 then
    self.hover_tooltip:set_hidden(false)
    local initial_box =
      Box.new(Position.zero(), HOVER_TOOLTIP_WIDTH, HOVER_TOOLTIP_HEIGHT)

    initial_box, _ = PlaceBox.position(initial_box, self:get_box(), {
      priority = { "top", "bottom" },
      padding = 8,
    })

    self.hover_tooltip:set_pos(initial_box.position)

    UI.root:append_child(self.hover_tooltip)
  else
    self.hover_tooltip:set_hidden(true)
    UI.root:remove_child(self.hover_tooltip)
    -- self:set_z(0)
  end
end

function SimpleGear:_render()
  --   if self.targets.entered == 1 then
  --     -- local x, y, w, h = self:get_geo()
  --     -- x = x - w / 2
  --     -- y = y - h / 2
  --     -- self.hover_tooltip:set_x(x)
  --     -- self.hover_tooltip:set_y(y)
  --     self.hover_tooltip:_render()
  --   end
end

return SimpleGear
