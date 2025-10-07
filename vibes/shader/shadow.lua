---@class (exact) vibes.ShaderShadow.Values
---@field shadow_offset? [number,number]
---@field shadow_color? [number,number,number,number]
---@field shadow_blur? number
---@field shadow_intensity? number

---@class (exact) vibes.ShaderShadow : vibes.Shader
---@field new fun(opts: vibes.ShaderShadow.Values): vibes.ShaderShadow
---@field init fun(self: vibes.ShaderShadow, opts: vibes.ShaderShadow.Values)
---@field send fun(self: vibes.ShaderShadow, values:vibes.ShaderShadow.Values)
local ShaderShadow = class("vibes.ShaderShadow", { super = Shader })

function ShaderShadow:init(opts)
  Shader.init(self, {
    src = "assets/shaders/shadow.frag",
    values = {
      shadow_offset = F.if_nil(opts.shadow_offset, { 0, 0 }),
      shadow_color = F.if_nil(opts.shadow_color, { 0, 0, 0, 0.7 }),
      shadow_blur = F.if_nil(opts.shadow_blur, 1),
      shadow_intensity = F.if_nil(opts.shadow_intensity, 2.0),
    },
  })
end

return ShaderShadow
