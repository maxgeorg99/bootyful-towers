local Container = require "ui.components.container"

---@class components.trophy.Overlay.Opts
---
---@class components.trophy.Overlay : Element
---@field new fun(opts: components.trophy.Overlay.Opts): components.trophy.Overlay
---@field init fun(self: components.trophy.Overlay, opts: components.trophy.Overlay.Opts)
---@field background number[]
local TrophyOverlay = class("components.trophy.Overlay", { super = Element })

function TrophyOverlay:init(_opts)
  self.background = { 0, 0, 0, 0 }
  self.box = Box.new(
    Position.new(0, 0),
    Config.window_size.width,
    Config.window_size.height
  )
  self.container = Container.new {
    box = self.box,
    background = self.background,
    interactable = true,
    z = Z.TROPHY_SELECTION_OVERLAY,
  }
  Element.init(self, self.box, {
    z = Z.TROPHY_SELECTION_OVERLAY,
    interactable = false,
  })
  self:append_child(self.container)
end

function TrophyOverlay:_update() self.background[4] = self._props.created / 2 end

function TrophyOverlay:_render() end

return TrophyOverlay
