do --copy
  ---@generic T
  ---@param t T
  ---@return T
  table.copy = function(t)
    local copy = {}
    for k, v in pairs(t) do
      copy[k] = v
    end
    return copy
  end
end

do -- deepcopy
  local function _deepcopy(orig, seen)
    local orig_type = type(orig)
    local copy

    -- Handle non-table types and nil
    if orig_type ~= "table" then
      return orig
    end

    -- Handle recursive references
    if seen[orig] then
      return seen[orig]
    end

    -- Create new table and track reference
    copy = {}
    seen[orig] = copy

    -- Copy all key/value pairs
    for orig_key, orig_value in next, orig, nil do
      copy[_deepcopy(orig_key, seen)] = _deepcopy(orig_value, seen)
    end

    -- Handle metatable
    local mt = getmetatable(orig)
    if mt then
      setmetatable(copy, _deepcopy(mt, seen))
    end

    return copy
  end

  ---@generic T
  ---@param t T
  ---@return T
  table.deepcopy = function(t)
    -- Initialize empty table to track seen references
    local seen = {}
    return _deepcopy(t, seen)
  end
end

do -- list_extend
  --- Extends a list IN PLACE! Does not create a copy!
  ---@generic T
  ---@param t T[]
  ---@param items T[]
  table.list_extend = function(t, items)
    for _, item in ipairs(items) do
      table.insert(t, item)
    end
  end
end

do -- is_empty
  ---@param t table
  ---@return boolean
  table.is_empty = function(t) return next(t) == nil end
end

do -- shift
  --- Removes the first item from the table, returns the item
  ---@generic T
  ---@param t T[]
  ---@return T
  table.shift = function(t)
    local item = table.remove(t, 1)
    return item
  end
end

do -- copy_list
  ---@generic T
  ---@param t T[]
  ---@return T[]
  table.copy_list = function(t)
    local copy = {}
    for _, item in ipairs(t) do
      table.insert(copy, item)
    end

    return copy
  end
end

do
  ---@param t any
  ---@return boolean
  table.is_list = function(t)
    return type(t) == "table" and next(t) ~= nil and t[1] ~= nil
  end
end

do -- flatten
  ---@param t any
  ---@return any
  table.flatten = function(t)
    local result = {}

    --- @param _t table<any,any>
    local function _tbl_flatten(_t)
      local n = #_t
      for i = 1, n do
        local v = _t[i]
        if type(v) == "table" and v[1] ~= nil then
          _tbl_flatten(v)
        elseif v ~= nil then
          table.insert(result, v)
        end
      end
    end
    _tbl_flatten(t)
    return result
  end
end

do
  table.count_of_items = function(t)
    local count = 0
    for _ in pairs(t) do
      count = count + 1
    end
    return count
  end
end

do
  table.keys = function(t, skip_sort)
    local keys = {}
    for k, _ in pairs(t) do
      table.insert(keys, k)
    end

    if not skip_sort then
      table.sort(keys)
    end
    return keys
  end
end

do
  ---@generic T
  ---@param t T[]
  ---@param item T
  ---@return number?
  table.find = function(t, item)
    for i, v in ipairs(t) do
      if v == item then
        return i
      end
    end
    return nil
  end
end

do
  table.range = function(start, stop)
    local range = {}
    for i = start, stop do
      table.insert(range, i)
    end
    return range
  end
end

do
  table.shuffle = function(t)
    for i = #t, 2, -1 do
      local j = math.random(1, i)
      t[i], t[j] = t[j], t[i]
    end
    return t
  end
end

do
  ---@param t any[]
  ---@param item any
  table.remove_item = function(t, item)
    for i, v in ipairs(t) do
      if v == item then
        table.remove(t, i)
        return true
      end
    end

    return false
  end
end

do -- swap
  ---@generic T
  ---@param t T[]
  ---@param i number
  ---@param j number
  table.swap = function(t, i, j)
    t[i], t[j] = t[j], t[i]
  end
end
