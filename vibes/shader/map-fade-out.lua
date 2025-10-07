---@class vibes.ShaderMapFadeOut.Values
---@field fadeEdge? number
---@field fadeColor? [number, number, number, number] # r,g,b,a
---@field fadeTime? number
---@field time? number

---@class vibes.ShaderMapFadeOut : vibes.Shader
---@field new fun(opts:vibes.ShaderMapFadeOut.Values): vibes.ShaderMapFadeOut
---@field init fun(self: vibes.ShaderMapFadeOut, opts:vibes.ShaderMapFadeOut.Values)
---@field send fun(self: vibes.ShaderMapFadeOut, values:vibes.ShaderMapFadeOut.Values)
local ShineShader = class("vibes.ShaderMapFadeOut", { super = Shader })

function ShineShader:init(opts)
  Shader.init(self, {
    src = "assets/shaders/map_fadeout.frag",
    values = {
      fadeEdge = F.if_nil(opts.fadeEdge, 0.3),
      fadeColor = F.if_nil(opts.fadeColor, { 0.1, 0.1, 0.15, 1.0 }),
      fadeTime = F.if_nil(opts.fadeTime, 0.0),
      time = F.if_nil(opts.time, 0.0),
    },
  })
end

return ShineShader
