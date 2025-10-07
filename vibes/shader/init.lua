---@class vibes.Shader.Opts
---@field src string
---@field values table<string, table|number|vibes.Texture|boolean>

---@class vibes.Shader : vibes.Class
---@field init fun(self:vibes.Shader, opts: vibes.Shader.Opts)
---@field new fun(opts: vibes.Shader.Opts)
---@field name string
---@field src string
---@field shader love.Shader
---@field values? table<string, table|number|vibes.Texture|boolean>
local Shader = class "vibes.Shader"

---@param opts vibes.Shader.Opts
function Shader:init(opts)
  validate(opts, {
    src = "string",
    values = "table",
  })

  self.src = opts.src
  self.shader = love.graphics.newShader(self.src)
  self.values = F.if_nil(opts.values, {})

  ---set defaults
  self:send(self.values)
end

---@param values table<string, table|number|vibes.Texture|boolean>
---@vararg number
function Shader:send(values)
  for key, value in pairs(values) do
    self.shader:send(key, value)
  end
end

function Shader:clone()
  return Shader.new { src = self.src, values = self.values }
end

--- @param other vibes.Shader
--- @return boolean
function Shader:eql(other) return self.id == other.id end

function Shader:__tostring()
  return string.format("Shader(%s, %s)", self.id, self.name)
end

return Shader
