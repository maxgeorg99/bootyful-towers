---@class vibes.Logging
---@field level number The current logging level (0=TRACE, 1=DEBUG, 2=INFO, 3=WARN, 4=ERROR, 5=FATAL)
---@field log_lines table The strings that haven't yet been written to stdout
---@field last_log_frame number The last frame which had the logs written to stdout
local Logger = {}

Logger.log_lines = {}
Logger.last_log_frame = 0
local WAIT_FRAMES = 5

-- Configuration - Change this to set the global log level
-- 0 = TRACE (most verbose)
-- 1 = DEBUG
-- 2 = INFO
-- 3 = WARN
-- 4 = ERROR
-- 5 = FATAL (least verbose)
Logger.level = 2

-- Level constants
Logger.TRACE = 0
Logger.DEBUG = 1
Logger.INFO = 2
Logger.WARN = 3
Logger.ERROR = 4
Logger.FATAL = 5

-- Color codes for different log levels
local colors = {
  [0] = { r = 0.6, g = 0.6, b = 0.6 }, -- TRACE: gray
  [1] = { r = 0.5, g = 0.5, b = 1.0 }, -- DEBUG: blue
  [2] = { r = 0.0, g = 0.8, b = 0.0 }, -- INFO: green
  [3] = { r = 1.0, g = 0.8, b = 0.0 }, -- WARN: yellow
  [4] = { r = 1.0, g = 0.4, b = 0.0 }, -- ERROR: orange
  [5] = { r = 1.0, g = 0.0, b = 0.0 }, -- FATAL: red
}

-- Level names
local level_names = {
  [0] = " TRACE ",
  [1] = " DEBUG ",
  [2] = " INFO ",
  [3] = " WARN ",
  [4] = " ERROR ",
  [5] = " FATAL ",
}

-- Format the current time
local function format_time()
  local time = os.date "*t"
  return string.format("%02d:%02d:%02d", time.hour, time.min, time.sec)
end

local function flush()
  local full_message = table.concat(Logger.log_lines)
  print(full_message)
  Logger.log_lines = {}
end

-- Get source information
local function get_source_info()
  local info = debug.getinfo(4, "Sl") -- 4 levels up to get the actual caller
  if info and info.short_src and info.currentline then
    local source = info.short_src:match "[^/\\]+$" or info.short_src -- Just the filename
    return string.format("%s:%d", source, info.currentline)
  end
  return "unknown:0"
end

local function append_to_log(message)
  if WAIT_FRAMES < 2 then
    print(message)
  end
  table.insert(Logger.log_lines, tostring(message))
  if
    Logger.last_log_frame < love.frame + WAIT_FRAMES
    and #Logger.log_lines > 0
  then
    -- Wait until we have all the strings to create one big string
    flush()
    Logger.last_log_frame = love.frame
  end
end

-- Core logging function
local function log(level, message, ...)
  if level < Logger.level then
    return
  end

  local formatted_message = message
  if select("#", ...) > 0 then
    formatted_message = string.format(message, ...)
  end

  local source = get_source_info()
  local log_str =
    string.format("[%s] %s - %s", level_names[level], source, formatted_message)

  -- Print to console with color if available
  if love and love.graphics then
    local r, g, b = love.graphics.getColor()
    love.graphics.setColor(colors[level].r, colors[level].g, colors[level].b)
    append_to_log(log_str)
    love.graphics.setColor(r, g, b)
  else
    append_to_log(log_str)
  end

  -- For fatal errors, we might want to trigger additional actions
  if level == Logger.FATAL then
    -- Optionally write to a file, display error dialog, etc.
  end
end

-- Public logging functions
function Logger.trace(message, ...) log(Logger.TRACE, message, ...) end
function Logger.debug(message, ...) log(Logger.DEBUG, message, ...) end
function Logger.info(message, ...) log(Logger.INFO, message, ...) end
function Logger.warn(message, ...) log(Logger.WARN, message, ...) end
function Logger.error(message, ...) log(Logger.ERROR, message, ...) end
function Logger.fatal(message, ...) log(Logger.FATAL, message, ...) end

-- Helper for conditionally logging
function Logger.log_if(condition, level, message, ...)
  if condition then
    log(level, message, ...)
  end
end

-- Helper for logging tables
function Logger.dump(level, value, label)
  if level < Logger.level then
    return
  end

  label = label or "Table"
  if type(value) ~= "table" then
    log(level, "%s: %s", label, tostring(value))
    return
  end

  local result = label .. " = {\n"
  local function dump_table(t, indent)
    local indent_str = string.rep("  ", indent)
    for k, v in pairs(t) do
      if type(v) == "table" then
        result = result .. indent_str .. tostring(k) .. " = {\n"
        dump_table(v, indent + 1)
        result = result .. indent_str .. "}\n"
      else
        result = result
          .. indent_str
          .. tostring(k)
          .. " = "
          .. tostring(v)
          .. "\n"
      end
    end
  end

  dump_table(value, 1)
  result = result .. "}"
  log(level, result)
end

return Logger
