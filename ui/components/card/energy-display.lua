local ScaledImage = require "ui.components.scaled-img"
local Text = require "ui.components.text"

---@class components.CardEnergyDisplay.Opts
---@field energy number
---@field box ui.components.Box
---@field z? number

---@class components.CardEnergyDisplay : Element
---@field init fun(self: components.CardEnergyDisplay, opts:components.CardEnergyDisplay.Opts)
---@field new fun(opts:components.CardEnergyDisplay.Opts)
---@field energy number
---@field font love.Font
---@field asset vibes.Texture
local CardEnergyDisplay =
  class("components.CardEnergyDisplay", { super = Element })

function CardEnergyDisplay:init(opts)
  validate(opts, { energy = "number" })

  Element.init(self, opts.box, {
    z = F.if_nil(opts.z, Z.BASE_CARD),
  })

  local _, _, w, h = self:get_geo()

  self:append_child(ScaledImage.new {
    box = Box.new(Position.zero(), w, h),
    texture = Asset.sprites.energy_orb,
    scale_style = "fit",
  })

  self:append_child(Text.new {
    tostring(opts.energy),
    box = Box.new(Position.zero(), w, h + 2),
    font = Asset.fonts.typography.h5,
    color = Colors.white:get(),
    text_align = "center",
    vertical_align = "center",
  })

  -- Can do an outline with this if we want.
  -- self:append_child(Text.new {
  --   tostring(opts.energy),
  --   box = Box.new(Position.zero(), self:get_width(), self:get_height()),
  --   font = Asset.fonts.typography.h3,
  --   color = Colors.black:get(),
  --   text_align = "center",
  --   vertical_align = "center",
  -- })

  self.energy = opts.energy
  self.font = Asset.fonts.typography.h2
  self.asset = Asset.sprites.card_energy_org
end

function CardEnergyDisplay:_render() end

return CardEnergyDisplay
