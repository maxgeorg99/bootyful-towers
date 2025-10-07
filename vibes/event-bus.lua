local listeners = {}

---@class EventBus
local EventBus = {}

--- @param t string
--- @param cb fun(...): nil
local function add_listener(t, cb)
  assert(type(cb) == "function", "you must provide a function to event bus")

  local cbs = listeners[t]
  if not cbs then
    listeners[t] = {}
    cbs = listeners[t]
  end

  table.insert(cbs, cb)
end

--- @param type string
--- @param cb fun(...): nil
local function remove_listener(type, cb)
  local cbs = listeners[type]
  if not cbs then
    return
  end

  for i, c in ipairs(cbs) do
    if c == cb then
      table.remove(cbs, i)
      break
    end
  end
end

--- @param type string
--- @param ... any
local function emit(type, ...)
  local cbs = listeners[type]
  if not cbs then
    return
  end

  for _, c in ipairs(cbs) do
    c(...)
  end
end

--- Register a listener and return a disposer that removes it
--- @param type string
--- @param cb fun(...): nil
--- @return fun(): nil disposer Disposer function to unregister
local function on(type, cb)
  add_listener(type, cb)
  return function() remove_listener(type, cb) end
end

--- @TODO fair, maybe pass in key / fn for listening
--- nice debugging

do
  --- @class vibes.event.CardPlayed
  --- @field card vibes.Card
  --- @param opts vibes.event.CardPlayed
  function EventBus:emit_card_played(opts) emit("card_played", opts) end

  --- @param fn fun(card: vibes.event.CardPlayed): nil
  function EventBus:listen_card_played(fn) return on("card_played", fn) end
end

do
  --- @class vibes.event.DrawHand
  --- @field hand vibes.Card[]

  --- @param opts vibes.event.DrawHand
  function EventBus:emit_draw_hand(opts) emit("draw_hand", opts) end

  --- @param fn fun(hand: vibes.event.DrawHand): nil
  function EventBus:listen_draw_hand(fn) return on("draw_hand", fn) end
end

do
  --- @class vibes.event.SelectCard
  --- @field card any
  --- @field selected boolean
  --- @param opts vibes.event.SelectCard
  function EventBus:emit_card_selected(opts) emit("card_selected", opts) end

  --- @param fn fun(hand: vibes.event.SelectCard): nil
  function EventBus:listen_card_selected(fn) return on("card_selected", fn) end
end

do
  ---@class vibes.event.EnemyDeath
  ---@field enemy vibes.Enemy
  ---@field tower vibes.Tower?
  ---@field kind DamageKind
  ---@field position vibes.Position

  ---@param event vibes.event.EnemyDeath
  function EventBus:emit_enemy_death(event) emit("enemy_death", event) end

  ---@param fn fun(enemy: vibes.event.EnemyDeath): nil
  function EventBus:listen_enemy_death(fn) return on("enemy_death", fn) end
end

do
  ---@class vibes.event.EnemyBlocked
  ---@field enemy vibes.Enemy
  ---@field blocked number
  ---@param event vibes.event.EnemyBlocked
  function EventBus:emit_enemy_blocked_damage(event)
    emit("enemy_blocked_damage", event)
  end

  ---@param fn fun(enemy: vibes.event.EnemyBlocked): nil
  function EventBus:listen_enemy_blocked_damage(fn)
    return on("enemy_blocked_damage", fn)
  end
end

do
  ---@class vibes.event.EnemyDamage
  ---@field enemy vibes.Enemy
  ---@field tower vibes.Tower?
  ---@field damage number
  ---@field kind DamageKind

  ---@param event vibes.event.EnemyDamage
  function EventBus:emit_enemy_damage(event) emit("enemy_damage", event) end

  ---@param fn fun(enemy: vibes.event.EnemyDamage): nil
  function EventBus:listen_enemy_damage(fn) return on("enemy_damage", fn) end
end

do
  ---@class vibes.event.EnemyReachedEnd
  ---@field enemy vibes.Enemy

  ---@param event vibes.event.EnemyReachedEnd
  function EventBus:emit_enemy_reached_end(event)
    emit("enemy_reached_end", event)
  end

  ---@param fn fun(enemy: vibes.event.EnemyReachedEnd): nil
  function EventBus:listen_enemy_reached_end(fn)
    return on("enemy_reached_end", fn)
  end
end

do
  ---@class vibes.event.EnemySpawned
  ---@field enemy vibes.Enemy

  ---@param event vibes.event.EnemySpawned
  function EventBus:emit_enemy_spawned(event) emit("enemy_spawned", event) end

  ---@param fn fun(enemy: vibes.event.EnemyReachedEnd): nil
  function EventBus:listen_enemy_spawned(fn) return on("enemy_spawned", fn) end
end

do
  ---@class vibes.event.TowerPlaced
  ---@field tower vibes.TowerCard

  ---@param event vibes.event.TowerPlaced
  function EventBus:emit_tower_placed(event) emit("tower_placed", event) end

  ---@param fn fun(enemy: vibes.event.TowerPlaced): nil
  function EventBus:listen_tower_placed(fn) return on("tower_placed", fn) end
end

do
  ---@class vibes.event.SpendGold
  ---@field gold number

  ---@param event vibes.event.SpendGold
  function EventBus:emit_spend_gold(event) emit("spend_gold", event) end

  ---@param fn fun(event: vibes.event.SpendGold): nil
  function EventBus:listen_spend_gold(fn) return on("spend_gold", fn) end
end

do -- Draw Card
  ---@class vibes.event.DrawCard
  ---@field card vibes.Card

  ---@param event vibes.event.DrawCard
  function EventBus:emit_card_draw(event) emit("draw_card", event) end

  ---@param fn fun(event: vibes.event.DrawCard): nil
  function EventBus:listen_card_draw(fn) return on("draw_card", fn) end
end

do -- Discard Card
  ---@class vibes.event.DiscardCard
  ---@field card vibes.Card

  ---@param event vibes.event.DiscardCard
  function EventBus:emit_card_discard(event) emit("discard_card", event) end

  ---@param fn fun(event: vibes.event.DiscardCard): nil
  function EventBus:listen_card_discard(fn) return on("discard_card", fn) end
end

do -- Player Block Gained
  ---@class vibes.event.PlayerBlockGained
  ---@field block number Amount of block gained
  ---@field total_block number Total block after gaining

  ---@param event vibes.event.PlayerBlockGained
  function EventBus:emit_player_block_gained(event)
    emit("player_block_gained", event)
  end

  ---@param fn fun(event: vibes.event.PlayerBlockGained): nil
  function EventBus:listen_player_block_gained(fn)
    return on("player_block_gained", fn)
  end
end

do -- Player Block Used
  ---@class vibes.event.PlayerBlockUsed
  ---@field block number Amount of block used
  ---@field total_block number Total block after using

  ---@param event vibes.event.PlayerBlockUsed
  function EventBus:emit_player_block_used(event)
    emit("player_block_used", event)
  end

  ---@param fn fun(event: vibes.event.PlayerBlockUsed): nil
  function EventBus:listen_player_block_used(fn)
    return on("player_block_used", fn)
  end
end

do -- Player Damage Blocked
  ---@class vibes.event.PlayerDamageBlocked
  ---@field damage_blocked number Amount of damage blocked
  ---@field total_damage number Total damage attempted
  ---@field remaining_damage number Damage that went through to health

  ---@param event vibes.event.PlayerDamageBlocked
  function EventBus:emit_player_damage_blocked(event)
    emit("player_damage_blocked", event)
  end

  ---@param fn fun(event: vibes.event.PlayerDamageBlocked): nil
  function EventBus:listen_player_damage_blocked(fn)
    return on("player_damage_blocked", fn)
  end
end

do -- Player Damage Taken
  ---@class vibes.event.PlayerDamageTaken
  ---@field damage number Amount of health damage taken
  ---@field health_before number Health before damage
  ---@field health_after number Health after damage

  ---@param event vibes.event.PlayerDamageTaken
  function EventBus:emit_player_damage_taken(event)
    emit("player_damage_taken", event)
  end

  ---@param fn fun(event: vibes.event.PlayerDamageTaken): nil
  function EventBus:listen_player_damage_taken(fn)
    return on("player_damage_taken", fn)
  end
end

do -- Player Damage Taken
  ---@class vibes.event.TowerUpgradeSelected
  ---@field upgrade tower.UpgradeOption

  ---@param event vibes.event.TowerUpgradeSelected
  function EventBus:emit_tower_upgrade_selected(event)
    emit("tower_upgrade_selected", event)
  end

  ---@param fn fun(event: vibes.event.TowerUpgradeSelected): nil
  function EventBus:listen_tower_upgrade_selected(fn)
    return on("tower_upgrade_selected", fn)
  end
end

do -- Player Discard Used
  ---@class vibes.event.PlayerDiscardUsed
  ---@field discards_used number Amount of discards used
  ---@field discards_remaining number Total discards remaining after use

  ---@param event vibes.event.PlayerDiscardUsed
  function EventBus:emit_player_discard_used(event)
    emit("player_discard_used", event)
  end

  ---@param fn fun(event: vibes.event.PlayerDiscardUsed): nil
  function EventBus:listen_player_discard_used(fn)
    return on("player_discard_used", fn)
  end
end

do -- Exhaust Card
  ---@class vibes.event.ExhaustCard
  ---@field card vibes.Card
  ---@field target Element?

  ---@param event vibes.event.ExhaustCard
  function EventBus:emit_card_exhaust(event) emit("exhaust_card", event) end

  ---@param fn fun(event: vibes.event.ExhaustCard): nil
  function EventBus:listen_card_exhaust(fn) return on("exhaust_card", fn) end
end

do -- Card Gained
  ---@class vibes.event.CardGained
  ---@field card vibes.Card

  ---@param event vibes.event.CardGained
  function EventBus:emit_card_gained(event) emit("card_gained", event) end

  ---@param fn fun(event: vibes.event.CardGained): nil
  function EventBus:listen_card_gained(fn) return on("card_gained", fn) end
end

do -- Tower Upgrade Menu Opened
  ---@class vibes.event.TowerUpgradeMenuOpened
  ---@field tower vibes.Tower

  ---@param event vibes.event.TowerUpgradeMenuOpened
  function EventBus:emit_tower_upgrade_menu_opened(event)
    emit("tower_upgrade_menu_opened", event)
  end

  ---@param fn fun(event: vibes.event.TowerUpgradeMenuOpened): nil
  function EventBus:listen_tower_upgrade_menu_opened(fn)
    return on("tower_upgrade_menu_opened", fn)
  end
end

do -- Tower Upgrade Menu Closed
  ---@class vibes.event.TowerUpgradeMenuClosed
  ---@field tower vibes.Tower

  ---@param event vibes.event.TowerUpgradeMenuClosed
  function EventBus:emit_tower_upgrade_menu_closed(event)
    emit("tower_upgrade_menu_closed", event)
  end

  ---@param fn fun(event: vibes.event.TowerUpgradeMenuClosed): nil
  function EventBus:listen_tower_upgrade_menu_closed(fn)
    return on("tower_upgrade_menu_closed", fn)
  end
end

do
  ---@class vibes.event.TowerStatUpgrade
  ---@field tower vibes.Tower
  ---@field upgrade tower.UpgradeOption|tower.EvolutionOption

  ---@param event vibes.event.TowerStatUpgrade
  function EventBus:emit_tower_stat_upgrade(event)
    emit("tower_stat_upgrade", event)
  end

  ---@param fn fun(event: vibes.event.TowerStatUpgrade): nil
  function EventBus:listen_tower_stat_upgrade(fn)
    return on("tower_stat_upgrade", fn)
  end
end

do -- Tower Critical Hit
  ---@class vibes.event.TowerCriticalHit
  ---@field tower vibes.Tower
  ---@field enemy vibes.Enemy
  ---@field base_damage number
  ---@field critical_damage number
  ---@field crits_triggered number

  ---@param event vibes.event.TowerCriticalHit
  function EventBus:emit_tower_critical_hit(event)
    emit("tower_critical_hit", event)
  end

  ---@param fn fun(event: vibes.event.TowerCriticalHit): nil
  function EventBus:listen_tower_critical_hit(fn)
    return on("tower_critical_hit", fn)
  end
end

do -- Game Speed Changed
  ---@class vibes.event.GameSpeedChanged
  ---@field old_speed number
  ---@field new_speed number

  ---@param event vibes.event.GameSpeedChanged
  function EventBus:emit_game_speed_changed(event)
    emit("game_speed_changed", event)
  end

  ---@param fn fun(event: vibes.event.GameSpeedChanged): nil
  function EventBus:listen_game_speed_changed(fn)
    return on("game_speed_changed", fn)
  end
end

do -- After Level End
  ---@param event hooks.AfterLevelEnd.Result
  function EventBus:emit_after_level_end(event) emit("after_level_end", event) end

  ---@param fn fun(event: hooks.AfterLevelEnd.Result): nil
  function EventBus:listen_after_level_end(fn) return on("after_level_end", fn) end
end

--- Remove a listener explicitly
--- @param type string
--- @param fn fun(...): nil
function EventBus:off(type, fn) remove_listener(type, fn) end

--- Reset all listeners (useful on hard mode switches)
function EventBus:reset() listeners = {} end

return EventBus
