---@class components.EnergyDisplay.Opts
---@field pos vibes.Position

---@class (exact) components.EnergyDisplay : Element
---@field new fun(opts: components.EnergyDisplay.Opts): components.EnergyDisplay
---@field init fun(self: components.EnergyDisplay, opts: components.EnergyDisplay.Opts)
local EnergyDisplay = class("components.EnergyDisplay", { super = Element })

local PADDING = 2
local WIDTH = 7
local COUNT = 10
local MAX_ENERGY = 10

---@param opts components.EnergyDisplay.Opts
function EnergyDisplay:init(opts)
  local box = Box.new(opts.pos, WIDTH * COUNT + PADDING * (COUNT - 1), WIDTH)

  Element.init(self, box, {
    name = "EnergyDisplay",
    z = Z.TOOLTIP,
  })
end

function EnergyDisplay:_render()
  local current_energy = State.player.energy

  -- Get element position and dimensions
  local x, y, w, h = self:get_geo()

  -- Start position (centered in our box)
  local start_x = x + PADDING
  local start_y = y

  -- Draw each orb
  for i = 1, MAX_ENERGY do
    local x = start_x + (i - 1) * (WIDTH + PADDING) * 2
    local y = start_y

    -- Choose sprite based on whether we have energy for this orb
    local sprite = i <= current_energy and Asset.sprites.energy_light_filled
      or Asset.sprites.energy_light_empty

    love.graphics.draw(sprite, x, y, 0, 2, 2)
  end
end

return EnergyDisplay
