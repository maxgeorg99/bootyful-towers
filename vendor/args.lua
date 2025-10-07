local M = {}

---comment
---@param args any
---@param flag any
---@return boolean
---@return integer
M.contains_flag = function(args, flag)
  for i, arg in ipairs(args) do
    if arg == flag then
      return true, i
    end
  end
  return false, 0
end

M.get_next_arg = function()
  -- Find the --texture-editor flag
  for i = 1, #arg do
    if arg[i] == "--texture-editor" and arg[i + 1] then
      return arg[i + 1]
    end
  end
  return nil
end

M.get_editor_tileset = function()
  -- Find the --editor flag
  for i = 1, #arg do
    if arg[i] == "--editor" and arg[i + 1] then
      return arg[i + 1]
    end
  end
  return "grass" -- Default to grass if no tileset specified
end

--- Parse level arguments from command line
--- Supports both --levels level1,level2,level3 and --levels level1 level2 level3
---@param args string[]
---@return string[]?
M.get_levels = function(args)
  local has_flag, flag_idx = M.contains_flag(args, "--levels")
  if not has_flag then
    return nil
  end

  local levels = {}
  local i = flag_idx + 1

  -- Check if the next argument contains commas (comma-separated format)
  if args[i] and string.find(args[i], ",") then
    -- Split by comma
    for level in string.gmatch(args[i], "([^,]+)") do
      level = level:match "^%s*(.-)%s*$" -- trim whitespace
      if level ~= "" then
        table.insert(levels, "assets/level-json/" .. level .. ".json")
      end
    end
  else
    -- Space-separated format - collect until next flag or end
    while args[i] and not string.find(args[i], "^%-%-") do
      local level = args[i]:match "^%s*(.-)%s*$" -- trim whitespace
      if level ~= "" then
        table.insert(levels, "assets/level-json/" .. level .. ".json")
      end
      i = i + 1
    end
  end

  return #levels > 0 and levels or nil
end

return M
