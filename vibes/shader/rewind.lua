---@class (exact) vibes.ShaderRewind.Values

---@class (exact) vibes.ShaderRewind : vibes.Shader
---@field new fun(opts: vibes.ShaderRewind.Values): vibes.ShaderRewind
---@field init fun(self: vibes.ShaderRewind, opts: vibes.ShaderRewind.Values)
---@field send fun(self: vibes.ShaderRewind, values:vibes.ShaderRewind.Values)
local ShaderRewind = class("vibes.ShaderRewind", { super = Shader })

function ShaderRewind:init(opts)
  Shader.init(self, {
    src = "assets/shaders/rewind.frag",
    values = {
      u_time = 0,
      ---@type [number, number]
      u_resolution = { 20, 20 },
    },
  })
end

return ShaderRewind
