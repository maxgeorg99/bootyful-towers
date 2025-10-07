local M = {}

M.reload = function(module)
  package.loaded[module] = nil
  return require(module)
end

M.reload_all = function()
  RELOADING = true

  local to_skip = {
    ["vibes.prelude"] = true,
    ["vibes.set.print"] = true,
    ["vibes.data.gamestate"] = true,
  }

  local to_reload = {}
  local unload = function(module)
    if to_skip[module] then
      return
    end

    if
      not (
        module:match "^vibes"
        or module:match "^vendor"
        or module:match "^ui"
      )
    then
      return
    end

    package.loaded[module] = nil
    table.insert(to_reload, module)
  end

  --
  for module in pairs(package.loaded) do
    unload(module)
  end

  -- package.loaded["vibes.prelude"] = nil
  -- require "vibes.prelude"
  -- require "vibes.set.print"
  -- require "ui.components.ui"
  Config = require "vibes.config"

  for _, module in ipairs(to_reload) do
    local ok, msg = pcall(require, module)
    if not ok then
      print(msg)
    end
  end

  RELOADING = false
end

-- Table to track when modules were last loaded
local module_timestamps = {}

-- Track last check time
local last_check_time = 0
local CHECK_INTERVAL = 0.1 -- 100ms in seconds

--- Hot reload all vibes modules if their files have been modified since last load
--- TODO: THIS DOESNT WORK!!
M.hot = function()
  -- Only check every 100ms
  local current_time = love.timer.getTime()
  if current_time - last_check_time < CHECK_INTERVAL then
    return false
  end
  last_check_time = current_time

  print "Checking for hot reloads"

  local reloaded = false
  -- Iterate through all loaded modules
  for module in pairs(package.loaded) do
    -- Only check modules that start with "vibes"
    if
      module:match "^vibes"
        and module ~= "vibes.data.gamestate"
        and module ~= "vibes.reload"
      or module:match "^ui"
    then
      -- Convert module name to file path for timestamp check
      local module_path = package.searchpath(module, package.path)
      if module_path then
        -- Get file info using the actual file path
        local absolute_path = love.filesystem.getSource()
          .. "/"
          .. (module_path:gsub("^./", ""))
        local info = love.filesystem.getInfo(absolute_path, "file")
        print("  Checking module: " .. module, absolute_path, inspect(info))
        if info then
          -- Check if module needs reloading
          local last_modified = info.modtime
          if not module_timestamps[module] then
            module_timestamps[module] = last_modified
          end

          if last_modified > module_timestamps[module] then
            print("Reloading module: " .. module)

            -- Update timestamp and reload
            module_timestamps[module] = last_modified
            package.loaded[module] = nil
            require(module)

            reloaded = true
          end
        end
      end
    end
  end

  return reloaded
end
return M
