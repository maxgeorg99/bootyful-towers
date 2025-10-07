---@class (exact) vibes.ShaderCloud.Values
---@field cloudColor? [number,number,number] # r,g,b
---@field cloudSpeed? number
---@field cloudDensity? number
---@field cloudScale? number

---@class (exact) vibes.ShaderCloud : vibes.Shader
---@field new fun(opts: vibes.ShaderCloud.Values): vibes.ShaderCloud
---@field init fun(self: vibes.ShaderCloud, opts: vibes.ShaderCloud.Values)
---@field send fun(self: vibes.ShaderCloud, values:vibes.ShaderCloud.Values)
local ShaderCloud = class("vibes.ShaderCloud", { super = Shader })

function ShaderCloud:init(opts)
  Shader.init(self, {
    src = "assets/shaders/cloud_shader.frag",
    values = {
      cloudColor = F.if_nil(opts.cloudColor, { 1.0, 1.0, 1.0 }),
      cloudSpeed = F.if_nil(opts.cloudSpeed, 0.5),
      cloudDensity = F.if_nil(opts.cloudDensity, 1.0),
      cloudScale = F.if_nil(opts.cloudScale, 1.6),
    },
  })
end

return ShaderCloud
