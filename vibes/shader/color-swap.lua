---@class (exact) vibes.ShaderColorSwap.Values
---@field palette? vibes.Texture
---@field paletteSize? [number, number] # width, height
---@field levelColumn? number

---@class (exact) vibes.ShaderColorSwap : vibes.Shader
---@field new fun(opts: vibes.ShaderColorSwap.Values): vibes.ShaderColorSwap
---@field init fun(self: vibes.ShaderColorSwap, opts: vibes.ShaderColorSwap.Values)
---@field send fun(self: vibes.ShaderColorSwap, values:vibes.ShaderColorSwap.Values)
local ShaderColorSwap = class("vibes.ShaderColorSwap", { super = Shader })

function ShaderColorSwap:init(opts)
  if not opts.palette then
    opts.palette = love.graphics.newImage "assets/sprites/armor-map.png"
  end

  opts.palette:setFilter("nearest", "nearest")

  Shader.init(self, {
    src = "assets/shaders/color_swap.frag",
    values = {
      palette = opts.palette,
      paletteSize = F.if_nil(
        opts.paletteSize,
        { opts.palette:getDimensions() }
      ),
      levelColumn = F.if_nil(opts.levelColumn, 0),
    },
  })
end

return ShaderColorSwap
