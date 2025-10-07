---@class (exact) vibes.ShaderShine.Values
---@field u_resolution? [number, number] # w, h
---@field u_mouse? [number, number], # x,y coordinates
---@field u_time? number,

---@class (exact) vibes.ShaderShine : vibes.Shader
---@field new fun(opts: vibes.ShaderShine.Values): vibes.ShaderShine
---@field init fun(self: vibes.ShaderShine, opts: vibes.ShaderShine.Values)
---@field send fun(self: vibes.ShaderShine, values:vibes.ShaderShine.Values)
local ShaderShine = class("vibes.ShaderShine", { super = Shader })

function ShaderShine:init(opts)
  Shader.init(self, {
    src = "assets/shaders/shine.frag",
    values = {
      u_resolution = F.if_nil(opts.u_resolution, { 0, 0 }),
      u_mouse = F.if_nil(opts.u_mouse, { 0, 0 }),
      u_time = F.if_nil(opts.u_time, 0),
    },
  })
end

return ShaderShine
