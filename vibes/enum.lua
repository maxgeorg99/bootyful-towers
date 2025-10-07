local Enum = {}

---@class Enum.Opts
---@field skip_value_check boolean

---Creates a new enum with the given LSP Enum
---@generic T
---@param name string The name of the enum
---@param values T The enum values
---@param opts? Enum.Opts
---@return T
function Enum.new(name, values, opts)
  opts = opts or {}

  local skip_value_check = F.if_nil(opts.skip_value_check, false)

  local list = {}
  local reverse_lookup = {}

  -- Create both key->value and value->key mappings
  for key, value in pairs(values) do
    assert(type(key) == "string", "Enum key must be a string")

    if not skip_value_check then
      assert(type(value) == "string", "Enum value must be a string")
      assert(key == value, "Enum key and value must be the same")
    end

    table.insert(list, value)
    reverse_lookup[value] = key
  end

  -- Make the enum immutable
  return setmetatable(values, {
    __index = function(_, k)
      if k == "_values" then
        return list
      end

      if k == "_enum" then
        return true
      end

      if rawget(values, k) then
        return rawget(values, k)
      end

      if reverse_lookup[k] then
        return rawget(values, reverse_lookup[k])
      end

      return error(string.format("Invalid key for enum '%s': %s", name, k))
    end,
    __newindex = function(_, k, v)
      error(string.format("Cannot modify enum '%s': %s -> %s", name, k, v))
    end,
    __tostring = function() return "Enum<" .. name .. ">" end,
  })
end

function Enum.values(enum)
  -- This isn't normally visible, but it's OK, this just makes LSP happy
  return enum._enum and enum._values
end

function Enum.length(enum) return #(Enum.values(enum) or {}) end

return Enum
