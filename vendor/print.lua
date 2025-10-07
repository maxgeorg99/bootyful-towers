if _HAS_LOADED_PRINT then
  return
end

OLD_PRINT = print
print = function(...)
  local items = { ... }
  for i, item in ipairs(items) do
    if type(item) ~= "string" then
      items[i] = inspect(item)
    end
  end
  OLD_PRINT(unpack(items))
end

-- Table to store recent messages with their timestamps
local recent_messages = {}
local last_cleanup = 0
local CLEANUP_INTERVAL = 2 -- Clean up every 2 seconds
local MESSAGE_TIMEOUT = 1 -- Messages expire after 1 second

-- Function to clean up old messages (older than 1 second)
local function cleanup_old_messages()
  local current_time = love.timer.getTime()
  if current_time - last_cleanup < CLEANUP_INTERVAL then
    return
  end

  local cutoff_time = current_time - MESSAGE_TIMEOUT
  for message, timestamp in pairs(recent_messages) do
    if timestamp < cutoff_time then
      recent_messages[message] = nil
    end
  end
  last_cleanup = current_time
end

-- Print a message only once per second
---@diagnostic disable-next-line: lowercase-global
print_once_per_second = function(...)
  local items = { ... }
  for i, item in ipairs(items) do
    if type(item) ~= "string" then
      items[i] = inspect(item)
    end
  end

  local message = table.concat(items, "\t")
  local current_time = love.timer.getTime()

  -- Clean up old messages periodically
  cleanup_old_messages()

  -- Check if we've seen this message recently
  if
    recent_messages[message]
    and (current_time - recent_messages[message]) < MESSAGE_TIMEOUT
  then
    return -- Don't print, message was sent too recently
  end

  -- Record this message and print it
  recent_messages[message] = current_time
  OLD_PRINT(unpack(items))
end

_HAS_LOADED_PRINT = true
