---@class vibes.ShaderEdgeOutline.Values
---@field outline_width? number
---@field edge_threshold? number
---@field outline_opacity? number
---@field texture_size [number,number] # width,height

---@class vibes.ShaderEdgeOutline : vibes.Shader
---@field new fun(values:vibes.ShaderEdgeOutline.Values): vibes.ShaderEdgeOutline
---@field init fun(self: vibes.ShaderEdgeOutline, values:vibes.ShaderEdgeOutline.Values)
---@field send fun(self: vibes.ShaderEdgeOutline, values:vibes.ShaderMapFadeOut.Values)
local ShineShader = class("vibes.ShaderMapFadeOut", { super = Shader })

function ShineShader:init(opts)
  Shader.init(self, {
    src = "assets/shaders/edge_outline.frag",
    values = {
      outline_width = F.if_nil(opts.outline_width, 0.8),
      outline_opacity = F.if_nil(opts.outline_opacity, 0.8),
      edge_threshold = F.if_nil(opts.edge_threshold, 0.1),
      texture_size = F.if_nil(opts.texture_size, { 0, 0 }),
    },
  })
end

return ShineShader
