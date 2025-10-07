---@class vibes.Player : vibes.Class
---@field new fun(opts: vibes.Player.Opts): vibes.Player
---@field init fun(self: vibes.Player, opts: vibes.Player.Opts)
---@field health number Player current health
---@field max_health number Player current health
---@field energy number Player current energy
---@field gold number Player current gold
---@field discards number Player current discards
---@field hand_size number Size of hand to draw at beginning of turn
---@field block number Player current block (absorbs damage)
local Player = class "vibes.Player"

---@class vibes.Player.Opts
---@field health number
---@field max_health number
---@field energy number
---@field gold number
---@field discards number
---@field hand_size number
---@field block number?

---@param opts vibes.Player.Opts
function Player:init(opts)
  validate(opts, {
    health = "number",
    max_health = "number",
    energy = "number",
    gold = "number",
    discards = "number",
  })

  self.health = opts.health
  self.max_health = opts.max_health
  self.energy = opts.energy
  self.gold = opts.gold
  self.discards = opts.discards
  self.hand_size = opts.hand_size
  self.block = opts.block or 0
end

---@param dmg number
function Player:take_damage(dmg)
  logger.debug("vibes/player.lua: Player took " .. dmg .. " damage")

  local blocked_damage = math.min(dmg, self.block)
  local remaining_damage = dmg - blocked_damage

  if blocked_damage > 0 then
    self.block = self.block - blocked_damage
    logger.debug(
      "vibes/player.lua: Player blocked "
        .. blocked_damage
        .. " damage, remaining block: "
        .. self.block
    )

    -- Emit damage blocked event
    EventBus:emit_player_damage_blocked {
      damage_blocked = blocked_damage,
      total_damage = dmg,
      remaining_damage = remaining_damage,
    }
  end

  if remaining_damage > 0 then
    self:damage_health(remaining_damage)
  end
end

---@param energy number
---@return  boolean
function Player:use_energy(energy)
  if self.energy < energy then
    logger.debug(
      "vibes/player.lua: Player could not use "
        .. energy
        .. " energy. Current: "
        .. self.energy
    )
    UI:create_user_message "Not enough energy"
    return false
  end

  logger.debug("vibes/player.lua: Player used " .. energy .. " energy")
  self.energy = self.energy - energy
  return true
end

---@param energy number
function Player:gain_energy(energy)
  logger.debug("vibes/player.lua: Player gained " .. energy .. " energy")
  self.energy = math.min(self.energy + energy, Config.player.max_energy)
end

---@param gold number
function Player:gain_gold(gold)
  -- TODO: Event?
  self.gold = self.gold + gold
end

---@param gold number
---@return boolean Whether the gold was able to be used or not.
function Player:use_gold(gold)
  if self.gold < gold then
    UI:create_user_message "Not enough gold"
    return false
  end

  logger.debug("vibes/player.lua: Player used " .. gold .. " gold")
  self.gold = self.gold - gold

  EventBus:emit_spend_gold { gold = gold }

  return true
end

---@param discards number?
---@return boolean Whether the discard was able to be used or not.
function Player:use_discards(discards)
  discards = discards or 1

  if self.discards < discards then
    UI:create_user_message "Not enough discards"
    return false
  end

  logger.debug("vibes/player.lua: Player used " .. discards .. " discard(s)")
  self.discards = self.discards - discards

  EventBus:emit_player_discard_used {
    discards_used = discards,
    discards_remaining = self.discards,
  }

  return true
end

---@param block number
function Player:gain_block(block)
  logger.debug("vibes/player.lua: Player gained " .. block .. " block")
  self.block = self.block + block

  EventBus:emit_player_block_gained {
    block = block,
    total_block = self.block,
  }
end

---@param block number
---@return boolean Whether the block was able to be used or not.
function Player:use_block(block)
  if self.block < block then
    return false
  end

  logger.debug("vibes/player.lua: Player used " .. block .. " block")
  self.block = self.block - block

  EventBus:emit_player_block_used {
    block = block,
    total_block = self.block,
  }

  return true
end

---@param damage number Amount of health damage to apply
function Player:damage_health(damage)
  if damage <= 0 then
    return
  end

  local health_before = self.health
  self.health = self.health - damage
  logger.debug("vibes/player.lua: Player took " .. damage .. " health damage")

  EventBus:emit_player_damage_taken {
    damage = damage,
    health_before = health_before,
    health_after = self.health,
  }

  if self.health <= 0 then
    State:trigger_game_over()
  end
end

function Player:heal(amount)
  self.health = math.min(self.health + amount, self.max_health)
end

function Player:set_block(block) self.block = block end

return Player
