---@class (exact) vibes.ShaderGrassNoise.Opts

---@class (exact) vibes.ShaderGrassNoise : vibes.Shader
---@field new fun(opts?: vibes.ShaderGrassNoise.Opts): vibes.ShaderGrassNoise
---@field init fun(self: vibes.ShaderGrassNoise, opts?: vibes.ShaderGrassNoise.Opts)
local ShaderGrassNoise = class("vibes.ShaderGrassNoise", { super = Shader })

---@param opts? vibes.ShaderGrassNoise.Opts
function ShaderGrassNoise:init(opts)
  opts = opts or {}

  validate(opts, {})

  Shader.init(self, {
    src = "assets/shaders/grass-noise.frag",
    values = {
      u_time = 0,
    },
  })
end

---Update the shader with current time
---@param time number
function ShaderGrassNoise:update_time(time) self:send { u_time = time } end

return ShaderGrassNoise
