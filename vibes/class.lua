---@class vibes.Class
---@field _type string
---@field id number|string
---@field is fun(any): self? Returns the object, cast as itself if it is the correct type

---@class vibes.Mixin
---@field create fun(cls: vibes.Class)
---@field init fun(self: vibes.Class)

---@class vibes.Class.Opts
---@field super? any
---@field get_id? fun(...): number|string
---@field encodable? boolean
---@field abstract? table<string, function|boolean>
---@field forbidden? table<string, boolean>
---@field mixin? vibes.Mixin[] A list of mixins to apply to the class

local accumulate_abstract = function(cls)
  local req = {}

  local current = cls
  while current do
    for name, _ in pairs(rawget(current, "_abstract") or {}) do
      if req[name] then
        error(string.format("`%s` duplicate: `%s`", cls._type, name))
      end

      req[name] = current
    end

    current = rawget(current, "_super")
  end

  if table.is_empty(req) then
    return nil
  end

  return req
end

local accumulate_forbidden = function(cls)
  local req = {}

  local current = cls
  while current do
    for name, _ in pairs(rawget(current, "_forbidden") or {}) do
      if req[name] then
        error(string.format("`%s` duplicate: `%s`", cls._type, name))
      end

      req[name] = current
    end

    current = rawget(current, "_super")
  end

  if table.is_empty(req) then
    return nil
  end

  return req
end

local _id = 1
local next_id = function()
  _id = _id + 1
  return _id
end

---@param type string
---@param opts? vibes.Class.Opts
return function(type, opts)
  opts = opts or {}

  local super = opts.super

  local class_mt = {}
  local class = setmetatable({
    _type = type,
    _super = super,
    _encodable = opts.encodable,
    _abstract = opts.abstract,
    _forbidden = opts.forbidden,
  }, class_mt)

  class_mt.__index = super
  class_mt.__call = function(_, ...) return class.new(...) end
  class_mt.__tostring = function() return string.format("Class(%s)", type) end

  local forbidden = accumulate_forbidden(class)
  if forbidden then
    class_mt.__newindex = function(cls, key, value)
      local forbidder = forbidden[key]
      if forbidder and forbidder ~= cls then
        error(string.format("cls[%s]: cannot set %s on %s", cls, key, type))
      end

      rawset(class, key, value)
    end
  end

  local instance_mt = {
    __index = class,
    __eq = function(a, b) return a.id == b.id end,
    __tostring = function(self)
      if class.__tostring then
        return class.__tostring(self)
      end

      return string.format("Instance(%s)", type)
    end,
  }

  local abstract = accumulate_abstract(class)

  if opts.mixin then
    assert(table.is_list(opts.mixin), "mixin must be a list, pass in a list")
    for _, mixin in ipairs(opts.mixin) do
      mixin.create(class)
    end
  end

  local get_id = opts.get_id or next_id

  function class.new(...)
    local instance = setmetatable({
      _class = class,
    }, instance_mt)

    instance.id = get_id(...)

    if super then
      -- This basically makes it so that access super on the instance
      -- returns something that continues to work up the tree every time you ask for super
      -- unless it's a field that is directly on the instance!
      instance._super = setmetatable({}, {
        __index = class._super._super,
        __newindex = instance,
      })

      -- The thing you ask for - you never actually mean to set something on super,
      -- you always actually want to set it on the instance.
      -- So let's do that.
      instance.super = setmetatable({}, {
        __index = function(_, key)
          if key == "super" then
            return instance._super
          end

          return super[key]
        end,
        __newindex = instance,
      })
    end

    -- Initialize the instance, this now has the right "super" chain
    instance:init(...)

    -- Initialize mixins, after the instance is initialized
    for _, mixin in ipairs(opts.mixin or {}) do
      mixin.init(instance)
    end

    if abstract then
      for name, method_cls in pairs(abstract) do
        local method = instance[name]
        local cls_method = method_cls[name]

        if not instance[name] or cls_method == method then
          error(
            string.format(
              "[%s] class `%s` must implement `%s`",
              instance._type,
              class._type,
              name
            )
          )
        end
      end
    end

    -- Return the instance
    return instance
  end

  function class.is(instance)
    if not instance then
      error(
        string.format("%s.is: instance must be a class, got %s", type, instance)
      )
    end

    local current = instance._class
    while current do
      if current._type == class._type then
        return instance
      end

      current = rawget(current, "_super")
    end

    return nil
  end

  if opts.encodable then
    local JSON = require "vendor.json"
    function class:to_json()
      local data = {}
      for k, v in pairs(self) do
        data[k] = v
      end
      return JSON.encode(data)
    end

    function class.decode(data)
      local instance = setmetatable({
        _class = class,
        _encodable = true,
      }, instance_mt)

      local decoded = JSON.decode(data)
      for key, value in pairs(decoded) do
        instance[key] = value
      end

      return instance
    end
  end

  return class
end
