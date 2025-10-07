local ScaledImage = require "ui.components.scaled-img"

---@class components.CardTowerLevelDisplay.Opts
---@field level number
---@field box ui.components.Box

---@class components.CardTowerLevelDisplay : Element
---@field init fun(self: components.CardTowerLevelDisplay, opts:components.CardTowerLevelDisplay.Opts)
---@field new fun(opts:components.CardTowerLevelDisplay.Opts)
---@field box ui.components.Box
---@field level number
---@field font love.Font
---@field asset vibes.Texture
local CardTowerLevelDisplay =
  class("components.CardTowerLevelDisplay", { super = Element })

function CardTowerLevelDisplay:init(opts)
  validate(opts, { level = "number", box = Box })

  Element.init(self, opts.box)

  self:append_child(ScaledImage.new {
    box = opts.box,
    texture = Asset.sprites.card_energy_org,
    scale_style = "fit",
  })

  self.level = opts.level
  self.font = Asset.fonts.typography.h3
  self.asset = Asset.sprites.card_energy_org
end

function CardTowerLevelDisplay:_render() end

return CardTowerLevelDisplay
