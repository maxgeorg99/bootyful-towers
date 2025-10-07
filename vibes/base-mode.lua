local Object = require "vendor.object"

---@class (exact) vibes.BaseMode
---@field name string
---@field enter fun(self: vibes.BaseMode)
---@field exit fun(self: vibes.BaseMode)
---@field update fun(self: vibes.BaseMode, dt: number)
---@field draw fun(self: vibes.BaseMode)
---@field mousemoved fun(self: vibes.BaseMode)
---@field textinput fun(self: vibes.BaseMode, text: string)
---@field keypressed fun(self: vibes.BaseMode, key: string)
---@field keyreleased fun(self: vibes.BaseMode, key: string)
---@field click fun(self: vibes.BaseMode)

local BaseMode = Object.new "vibes.BaseMode"

local callbacks = {
  "enter",
  "update",
  "draw",
}

local optional_callbacks = {
  "exit",
  "mousemoved",
  "textinput",
  "keypressed",
  "keyreleased",
  "click",
}

---@param mode vibes.BaseMode
---@return vibes.BaseMode
function BaseMode.wrap(mode)
  for _, name in ipairs(callbacks) do
    assert(mode[name], string.format("Mode %s must implement %s", mode, name))
    local callback = mode[name]
    mode[name] = function(...)
      logger.trace("mode:event: %s", name)
      return callback(...)
    end
  end

  for _, name in ipairs(optional_callbacks) do
    if mode[name] then
      local callback = mode[name]
      mode[name] = function(...)
        logger.trace("mode:event: %s", name)
        return callback(...)
      end
    else
      mode[name] = function()
        if name == "mousemoved" then
          return
        end
        -- logger.info("mode:event:%s // not handled", name)
      end
    end
  end

  return mode
end

return BaseMode
