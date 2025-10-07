---@class (exact) vibes.ShaderEdgeGlowThrob.Values
---@field glow_radius? number
---@field glow_intensity? number
---@field glow_color? [number, number,number] # r,g,b
---@field glow_falloff? number
---@field texture_size [number,number] # width, height

---@class (exact) vibes.ShaderEdgeGlowThrob : vibes.Shader
---@field new fun(opts: vibes.ShaderEdgeGlowThrob.Values): vibes.ShaderEdgeGlowThrob
---@field init fun(self: vibes.ShaderEdgeGlowThrob, opts: vibes.ShaderEdgeGlowThrob.Values)
---@field send fun(self: vibes.ShaderEdgeGlowThrob, values:vibes.ShaderEdgeGlowThrob.Values)
local ShineShader = class("vibes.ShaderEdgeGlowThrob", { super = Shader })

function ShineShader:init(opts)
  Shader.init(self, {
    src = "assets/shaders/edge-glow-throb.frag",
    values = {
      glow_radius = F.if_nil(opts.glow_radius, 20.0),
      glow_intensity = F.if_nil(opts.glow_intensity, 0.8),
      glow_color = F.if_nil(opts.glow_color, { 1.0, 1.0, 0.0 }),
      glow_falloff = F.if_nil(opts.glow_falloff, 2.0),
      texture_size = F.if_nil(opts.texture_size, { 0, 0 }),
    },
  })
end

return ShineShader
