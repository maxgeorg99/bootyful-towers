local json = require "vendor.json"

local Save = {}

--- Returns true if the player has a saved game.
--- @return boolean
function Save.PlayerHasSavedGame()
  local fd = love.filesystem.getInfo "save.json"
  if fd ~= nil and fd.size > 0 then
    logger.debug "Player has save file."
    return true
  end
  logger.debug "Player has no save file."
  return false
end

function Save.SaveGame()
  local save_file = love.filesystem.newFile "save.json"
  local data = {}
  data["character_kind"] = CharacterKind[State.selected_character]
  data["player_data"] = {
    gold = State.player.gold,
    health = State.player.health,
    max_health = State.player.max_health,
    energy = State.player.energy,
    hand_size = State.player.hand_size,
  }
  -- data["player_gear"] = {}
  local save_data = json.encode(data)
  if save_data == nil or save_data == "" then
    error "I ain't save shit"
  end
  save_file:write(save_data)
end

function Save.LoadGame()
  local fd = love.filesystem.getInfo "save.json"
  if not fd then
    error "No save file found. Make sure you call `Save.PlayerHasSavedGame()` to check first, idiot."
  end
  if not (fd.size > 0) then
    error "Save file is empty"
  end
  local save_data = love.filesystem.read "save.json"
  local data = json.decode(save_data)
  if data == nil then
    love.filesystem.remove "save.json"
    error "I ain't got nothin' to decode, playa"
  end
  State.selected_character = data["character_kind"]
  State.player.gold = data["player_data"]["gold"]
  State.player.health = data["player_data"]["health"]
  State.player.max_health = data["player_data"]["max_health"]
  State.player.energy = data["player_data"]["energy"]
  State.player.hand_size = data["player_data"]["hand_size"]
end

return Save
