local BlockDisplay = require "ui.components.player.block-display"
local HealthBar = require "ui.components.player.health-bar"
local ScaledImage = require "ui.components.scaled-img"

local Text = require "ui.components.text"
---@class (exact) hud.Player : Element
---@field new fun(opts: hud.Player.Opts): hud.Player
---@field init fun(self: hud.Player, opts: hud.Player.Opts)
---@field asset vibes.Texture
local Hud = class("hud.Player", { super = Element })

---@class hud.Player.Opts

local SCALE = 2
local BASE_W = 254
local BASE_H = 61

--- @param opts hud.Player.Opts
function Hud:init(opts)
  validate(opts, {})

  local box =
    Box.new(Position.new(0 * SCALE, 4 * SCALE), BASE_W * SCALE, BASE_H * SCALE)

  Element.init(self, box, { z = Z.HUD })

  self:_setup(box)
end

function Hud:_setup(box)
  local x, y = self:get_geo()
  local character_asset = ScaledImage.new {
    box = Box.new(
      Position.new(x + 13 * SCALE, y + 10 * SCALE),
      47 * SCALE,
      45 * SCALE
    ),
    scale_style = "fill",
    texture = State:get_character_sprite(),
  }

  local hud_asset = ScaledImage.new {
    box = box,
    scale_style = "fit",
    texture = Asset.ui.hud,
  }

  local health = Text.new {
    function()
      local current = State.player.health
      if current < 0 then
        current = 0
      end
      if current > 999 then
        current = 999
      end
      return {
        {
          text = tostring(math.floor(current)),
          color = Colors.white,
        },
      }
    end,
    box = Box.new(
      Position.new(x + (178 * SCALE), y + (-6 * SCALE)),
      35 * SCALE,
      50 * SCALE
    ),
    font = Asset.fonts.typography.hud.numbers,
    vertical_align = "center",
    text_align = "left",
  }

  -- Block display positioned below health bar
  local block_display = BlockDisplay.new {
    box = Box.new(Position.new(x + 60, y + 55), 220, 35),
  }
  self:append_child(block_display)

  local gold = Text.new {
    function()
      local current = State.player.gold
      if current > 999999 then
        current = 999999
      end
      return {
        {
          text = tostring(current),
          color = Colors.white,
        },
      }
    end,
    box = Box.new(
      Position.new(x + (99 * SCALE), y + (38 * SCALE)),
      45 * SCALE,
      13 * SCALE
    ),
    font = Asset.fonts.typography.hud.numbers,
    vertical_align = "center",
    text_align = "left",
  }

  local health_bar = HealthBar.new(
    Box.new(
      Position.new(x + (72 * SCALE), y + (10.5 * SCALE)),
      103 * SCALE,
      15 * SCALE
    )
  )

  gold:set_z(Z.HUD + 5)
  health:set_z(Z.HUD + 5)
  health_bar:set_z(Z.HUD + 5)

  self:append_child(character_asset)
  self:append_child(hud_asset)
  self:append_child(gold)
  self:append_child(health)
  self:append_child(health_bar)
end

function Hud:_render()
  local x, y = self:get_geo()

  self:with_color(
    Colors.black:opacity(0.66),
    function()
      love.graphics.rectangle(
        "fill",
        x + (16 * SCALE),
        y + (12 * SCALE),
        47 * SCALE,
        45 * SCALE
      )
    end
  )
end

function Hud:_update() end
function Hud:_focus() end
function Hud:_blur() end

return Hud
