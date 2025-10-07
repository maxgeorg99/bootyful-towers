---@class vibes.ShaderOutline.Values
---@field outline_width? number
---@field outline_color? [number,number,number,number] # r,g,b,a
---@field texture_size [number,number] # width,height

---@class vibes.ShaderOutline : vibes.Shader
---@field new fun(values:vibes.ShaderOutline.Values): vibes.ShaderOutline
---@field init fun(self: vibes.ShaderOutline, values:vibes.ShaderOutline.Values)
---@field send fun(self: vibes.ShaderOutline, values:vibes.ShaderOutline.Values)
local OutlineShader = class("vibes.ShaderOutline", { super = Shader })

function OutlineShader:init(opts)
  Shader.init(self, {
    src = "assets/shaders/outline.frag",
    values = {
      outline_color = F.if_nil(opts.outline_color, { 1.0, 1.0, 1.0, 1.0 }),
      outline_width = F.if_nil(opts.outline_width, 2.0),
      textureSize = F.if_nil(opts.texture_size, { 144, 144 }),
    },
  })
end

return OutlineShader
