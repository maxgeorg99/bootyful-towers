local M = {}

--- Create a new class
---@param class_type string
---@return table
function M.new(class_type)
  local obj = {}
  obj.__index = obj
  obj._type = class_type
  return obj
end

--- Inherit from a parent class
---@generic T
---@param parent T
---@return { super: T }
function M.inherit(parent, type)
  local child = { super = parent }
  child.__index = child
  child._type = type
  return setmetatable(child, { __index = parent })
end

return M
