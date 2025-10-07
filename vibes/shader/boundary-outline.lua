---@class vibes.ShaderBoundaryOutline.Values
---@field outline_width? number
---@field outline_color? [number,number,number,number] # r,g,b,a
---@field feather_amount? number
---@field scale_factor? number
---@field texture_size [number,number] # width,height

---@class vibes.ShaderBoundaryOutline : vibes.Shader
---@field new fun(values:vibes.ShaderBoundaryOutline.Values): vibes.ShaderBoundaryOutline
---@field init fun(self: vibes.ShaderBoundaryOutline, values:vibes.ShaderBoundaryOutline.Values)
---@field send fun(self: vibes.ShaderBoundaryOutline, values:vibes.ShaderBoundaryOutline.Values)
local BoundaryOutlineShader =
  class("vibes.ShaderBoundaryOutline", { super = Shader })

function BoundaryOutlineShader:init(opts)
  Shader.init(self, {
    src = "assets/shaders/boundary_outline.frag",
    values = {
      outline_color = F.if_nil(opts.outline_color, { 1.0, 1.0, 1.0, 1.0 }),
      feather_amount = F.if_nil(opts.feather_amount, 0.0),
      scale_factor = F.if_nil(opts.scale_factor, 1.0),
      texture_size = F.if_nil(opts.texture_size, { 0, 0 }),
    },
  })
end

return BoundaryOutlineShader
