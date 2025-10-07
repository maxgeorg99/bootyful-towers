---@class (exact) vibes.ShaderCardTilt.Values
---@field mouse_pos? [number,number] # x, y
---@field card_size? [number,number] # x, y
---@field tile_strength? number
---
---@class (exact) vibes.ShaderCardTilt : vibes.Shader
---@field new fun(opts: vibes.ShaderCardTilt.Values): vibes.ShaderCardTilt
---@field init fun(self: vibes.ShaderCardTilt, opts: vibes.ShaderCardTilt.Values)
---@field send fun(self: vibes.ShaderCardTilt, values:vibes.ShaderCardTilt.Values)
local ShaderCardTilt = class("vibes.ShaderCardTilt", { super = Shader })

function ShaderCardTilt:init(opts)
  Shader.init(self, {
    src = "assets/shaders/card-tilt.frag",
    values = {
      rotation_angles = F.if_nil(opts.mouse_pos, { 0, 0 }),
      -- card_size = F.if_nil(opts.card_size, { 0, 0 }),
      perspective_distance = F.if_nil(opts.tile_strength, 1.5),
    },
  })
end

return ShaderCardTilt
