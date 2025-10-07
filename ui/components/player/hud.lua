local BlockDisplay = require "ui.components.player.block-display"
local Container = require "ui.components.container"
local Hud = require "ui.elements.hud"

--- @class ui.components.player.HUD : Element

--- @param opts { }
--- @return ui.components.player.HUD
return function(opts)
  -- Create the main HUD container
  local hud = Container.new {
    box = Box.new(Position.new(0, 0), 800, 180),
    z = Z.HUD,
  }

  hud.name = "PlayerHUD"

  local hud_display = Hud.new {}
  hud:append_child(hud_display)

  hud.z = Z.HUD

  return hud --[[@as ui.components.player.HUD ]]
end
