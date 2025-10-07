---@class (exact) vibes.ShaderCard3DTilt.Values
---@field u_mouse? [number, number] # Mouse position relative to card (0-1 range)
---@field u_tilt_strength? number # How strong the tilt effect is (default: 0.3)

---@class (exact) vibes.ShaderCard3DTilt : vibes.Shader
---@field new fun(opts: vibes.ShaderCard3DTilt.Values): vibes.ShaderCard3DTilt
---@field init fun(self: vibes.ShaderCard3DTilt, opts: vibes.ShaderCard3DTilt.Values)
---@field send fun(self: vibes.ShaderCard3DTilt, values: vibes.ShaderCard3DTilt.Values)
local ShaderCard3DTilt = class("vibes.ShaderCard3DTilt", { super = Shader })

---@param opts vibes.ShaderCard3DTilt.Values
function ShaderCard3DTilt:init(opts)
  Shader.init(self, {
    src = "assets/shaders/card-3d-tilt.frag",
    values = {
      u_mouse = F.if_nil(opts.u_mouse, { -1, -1 }),
      u_tilt_strength = F.if_nil(opts.u_tilt_strength, 0.2),
    },
  })
end

return ShaderCard3DTilt
