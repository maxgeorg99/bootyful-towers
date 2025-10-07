--[[
  Example Usage:

  validate(opts, {
    kind = CardKind,
    name = "string",
    description = "string",
    energy = "number",
    texture = "userdata",
    rarity = CardRarity,
    after_play_kind = CardAfterPlay,
  })

--]]

---@class validate.List.Options: { [1]: any }

---@class (exact) validate.List : vibes.Class
---@field new fun(opts: validate.List.Options): validate.List
---@field init fun(self: validate.List, opts: validate.List.Options)
---@field ty any
List = class "validate.List"

function List:init(opts)
  self.ty = assert(opts[1], "List must have a type in first position.")
end

---@class validate.Optional.Options: { [1]: any }

---@class (exact) validate.Optional : vibes.Class
---@field new fun(opts: validate.Optional.Options): validate.Optional
---@field init fun(self: validate.Optional, opts: validate.Optional.Options)
---@field ty any
Optional = class "validate.Optional"

function Optional:init(opts)
  self.ty = assert(opts[1], "Optional must have a type in first position.")
end

---@class validate.Either.Options: { [1]: any, [2]: any }

---@class (exact) validate.Either : vibes.Class
---@field new fun(opts: validate.Either.Options): validate.Either
---@field init fun(self: validate.Either, opts: validate.Either.Options)
---@field left any
---@field right any
Either = class "validate.Either"

function Either:init(opts)
  self.left = assert(opts[1], "Union must have a type in first position.")
  self.left = assert(opts[1], "Union must have a type in first position.")
end

local assert_type = function(ty, key, value)
  if type(value) == ty then
    return
  end

  error(
    string.format(
      "[%s] Expected '%s', got '%s' => %s",
      key,
      ty,
      type(value),
      value
    )
  )
end

local inner_check

---@param key string|number
---@param value any
---@param ty any
inner_check = function(key, value, ty)
  -- Check for optional fields, update ty if necessary
  if type(ty) == "string" then
    local last_char = string.sub(ty, -1)
    if last_char == "?" then
      ty = string.sub(ty, 1, -2)

      if value[key] == nil then
        return
      end
    end
  end

  if ty == "userdata" then
    assert_type("userdata", key, value[key])
  elseif ty == "number" then
    assert_type("number", key, value[key])
  elseif ty == "string" then
    assert_type("string", key, value[key])
  elseif ty == "boolean" then
    assert_type("boolean", key, value[key])
  elseif ty == "function" then
    assert_type("function", key, value[key])
  elseif ty == "table" then
    assert_type("table", key, value[key])
  elseif type(ty) == "function" then
    ty(key, value[key])
  elseif type(ty) == "table" then
    if ty._enum then
      assert(
        ty[value[key]],
        string.format(
          "[%s] Expected valid enum value, got '%s' = %s",
          key,
          type(value[key]),
          value[key]
        )
      )
    elseif List.is(ty) then
      ---@cast ty validate.List

      for i, _ in ipairs(value[key]) do
        if not type(i == "number") then
          error "List index must be a number, cannot have other keys"
        end

        inner_check(i, value[key], ty.ty)
      end
    elseif Either.is(ty) then
      ---@cast ty validate.Either

      local is_left = pcall(inner_check, key, value, ty.left)
      local is_right = pcall(inner_check, key, value, ty.right)

      if not is_left and not is_right then
        error(
          string.format(
            "[%s] Expected %s or %s, got %s",
            key,
            ty.left._type or ty.left.name,
            ty.right._type or ty.right.name,
            type(value[key])
          )
        )
      end
    elseif Optional.is(ty) then
      ---@cast ty validate.Optional

      if value[key] == nil then
        return
      end

      inner_check(key, value, ty.ty)
    elseif ty.is then
      local val = value[key]
      assert(
        ty.is(value[key]),
        string.format(
          "[key:%s] Expected %s, got %s",
          key,
          ty._type or ty.name,
          val._type or val.name or type(val)
        )
      )
    else
      error(
        string.format(
          "[%s] Expected %s, got %s - but had not way to validate",
          key,
          ty._type or ty.name,
          type(value[key])
        )
      )
    end
  end
end

---@param value any
---@param rule table
return function(value, rule)
  -- TODO: In production build, this is a noop.
  if PRODUCTION then
    return
  end

  if not type(value) == "table" then
    error(
      string.format("Expected table, got %s: %s", type(value), tostring(value))
    )
  end

  for key, ty in pairs(rule) do
    inner_check(key, value, ty)
  end
end
