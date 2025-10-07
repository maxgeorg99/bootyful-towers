local Commander = {}

-- [[
-- Commander exists to serve. It executes commands from the dev
-- console.
--
-- set level
-- set gold
-- set enemy spawn count
-- set health <number>
-- reload <module name>
-- set log level
-- set energy
-- give <card>
-- give tower xp
-- reload all
--
-- Example commands:
-- - help
-- - give gold 150
-- - set level 7
-- etc.
-- ]]

--- The big boi. Parse through shit and try to make sense of
--- what is being said/what commands are being given and then
--- execute on them.
--- @param input string
function Commander.execute(input)
  input = input:lower()
  logger.debug("Executing command `" .. input .. "`")
  local words = {}
  for word in string.gmatch(input, "%S+") do
    table.insert(words, word)
  end

  if words[1] == "give" then
    Commander.give(words)
  elseif words[1] == "set" then
    Commander.set(words)
  elseif words[1] == "reload" then
    Commander.reload(words)
  else
    logger.info("Received invalid command: " .. input)
  end
end

--- @param input table<string>
function Commander.set(input)
  if input[2] == "level" then
    logger.info("Setting level to " .. input[3])
  elseif input[2] == "gold" then
    logger.info("Setting gold to " .. input[3])
  elseif input[2] == "health" then
    logger.info("Setting player health to " .. input[3])
  else
    logger.info("Received invalid `Set` subcommand: " .. input[2])
  end
end

--- @param input table<string>
function Commander.reload(input) package.loaded[input[2]] = nil end

--- Do any givings
--- @param input table<string>
function Commander.give(input)
  local amt = tonumber(input[3])
  if not amt then
    logger.info(input[3] .. " is not a valid amount to give.")
    return
  end

  if input[2] == "gold" then
    Commander.give_gold(amt)
  elseif input[2] == "card" then
    logger.info "YOU GET A CARD"
  else
    logger.info("Received invalid `Give` subcommand: " .. input[2])
  end
end

--- Attempts to give player an amount of gold.
--- If amount is greater than current gold, set gold to zero.
--- @param amount number
function Commander.give_gold(amount)
  logger.debug("Giving player " .. amount .. " gold.")
  local new_gold = State.player.gold + amount
  if new_gold < 0 then
    new_gold = 0
  end
  State.player.gold = new_gold
end

function Commander.give_card() end

return Commander
