---@class vibes.System
---@field name string
---@field update fun(self: any, dt: number)
---@field draw fun(self: any)
---@field destroy fun(self: any)?
System = class("vibes.System", {
  abstract = {
    name = true,
    update = true,
    draw = true,
  },
})

---@class (exact) vibes.SystemManagerOptions
---@field systems vibes.System[]

---@class (exact) vibes.SystemManager : vibes.Class
---@field new fun(opts: vibes.SystemManagerOptions): vibes.SystemManager
---@field init fun(self: vibes.SystemManager, opts: vibes.SystemManagerOptions)
---@field systems vibes.System[]
local SystemManager = class "vibes.SystemManager"

---@param opts vibes.SystemManagerOptions
function SystemManager:init(opts) self.systems = opts.systems end

function SystemManager:update(dt)
  for _, plugin in ipairs(self.systems) do
    plugin:update(dt)
  end
end

function SystemManager:draw()
  for _, plugin in ipairs(self.systems) do
    plugin:draw()
  end
end

--- Destroy systems by calling optional destroy() on each, in reverse order
function SystemManager:destroy()
  for i = #self.systems, 1, -1 do
    local plugin = self.systems[i]
    if plugin.destroy then
      plugin:destroy()
    end
  end
end

return SystemManager
