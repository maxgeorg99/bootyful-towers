---@class hook.AfterEnemySpawn.Opts
---@field enemy vibes.Enemy

---@class hooks.FireState
---@field fire_growth number

---@class hooks.PoisonState
---@field poison_growth number

---@alias hook.AfterEnemySpawn fun(self: any, opts: hook.AfterEnemySpawn.Opts)

---@class vibes.effect.VibeTowerStats
---@field stats tower.StatsManager

---@alias vibes.BeforeTowerAttack fun(self: any, tower: vibes.Tower, result: vibes.effect.VibeTowerStats)
---@alias vibes.AfterTowerAttack fun(self: any, tower: vibes.Tower)

---@class vibes.effect.BeforePlayingActionsState
---@field energy number

---@class hooks.OnCardInfoResult
---@field card vibes.Card
---@field modified_energy number

do
  ---@class hooks.BeforeLevelStart.Result
  ---@field level vibes.Level
  ---@field energy number
  ---@field discards number

  ---@alias vibes.BeforeLevelStarts fun(self: any, result: hooks.BeforeLevelStart.Result)
end

do
  ---@class hooks.AfterLevelEnd.Result
  ---@field level vibes.Level

  ---@alias vibes.AfterLevelEnd fun(self: any, level: vibes.Level)
end

do
  ---@class hooks.OnTowerCriticalHit.Result
  ---@field tower vibes.Tower
  ---@field enemy vibes.Enemy
  ---@field base_damage number
  ---@field critical_damage number
  ---@field crits_triggered number

  ---@alias vibes.OnTowerCriticalHit fun(self: any, result: hooks.OnTowerCriticalHit.Result)
end

do
  ---@class hooks.OnShopInfoResult
  ---@field card? vibes.Card
  ---@field pack? vibes.ShopPack
  ---@field price number
end

---@alias vibes.BeforePlayingActions fun(self: any, result: vibes.effect.BeforePlayingActionsState)
---@alias vibes.effect.AfterEnemyDeath fun(self: any, enemy: vibes.Enemy)
---@alias hooks.BeforeLevelStart fun(self: any, wave: enemy.Wave)
---@alias vibes.OnCardPlayed fun(self: any, card: vibes.Card)

---@class (exact) vibes.effect.HookParams
---@field before_playing_actions? vibes.BeforePlayingActions
---@field before_level_starts? vibes.BeforeLevelStarts
---@field before_wave_starts? hooks.BeforeLevelStart
---@field after_wave_ends? fun(self: any, opts: hooks.AfterWaveEnds.Result)
---@field after_level_end? fun(self: any, opts: hooks.AfterLevelEnd.Result)
---@field on_card_played? vibes.OnCardPlayed
--
-- Tower Fields
---@field before_tower_attack? vibes.BeforeTowerAttack?
---@field after_tower_attack? vibes.AfterTowerAttack
--
-- Enemy Fields
---@field after_enemy_spawn? hook.AfterEnemySpawn
---@field after_enemy_death? vibes.effect.AfterEnemyDeath
--
-- Poison Fields
---@field on_poison_tick? fun(self: any, poison_state: hooks.PoisonState)
--
-- Critical Fields
---@field on_tower_critical_hit? vibes.OnTowerCriticalHit
--
-- Card Fields
---@field on_card_drawn? fun(self: any, card: vibes.Card)
---@field on_card_discarded? fun(self: any, card: vibes.Card)
---@field on_card_info? fun(self: any, info: hooks.OnCardInfoResult)
--
-- Shop Fields
---@field on_shop_info? fun(self: any, info: hooks.OnShopInfoResult)

---@class hooks.AfterWaveEnds.Result
---@field wave enemy.Wave

---@class vibes.Hooks
---@field before_playing_actions vibes.BeforePlayingActions
---@field before_tower_attack vibes.BeforeTowerAttack
---@field after_tower_attack vibes.AfterTowerAttack
---@field before_wave_starts hooks.BeforeLevelStart
---@field before_level_starts vibes.BeforeLevelStarts
---@field after_wave_ends fun(self: any, opts: hooks.AfterWaveEnds.Result)
---@field after_level_end fun(self: any, opts: hooks.AfterLevelEnd.Result)
---@field on_card_played vibes.OnCardPlayed
---@field after_enemy_spawn hook.AfterEnemySpawn
---@field after_enemy_death vibes.effect.AfterEnemyDeath
---@field on_poison_tick fun(self: any, poison_state: hooks.PoisonState)
---@field on_fire_tick fun(self: any, fire_state: hooks.FireState)
---@field on_tower_critical_hit vibes.OnTowerCriticalHit
---@field on_card_drawn? fun(self: any, card: vibes.Card)
---@field on_card_discarded? fun(self: any, card: vibes.Card)
---@field on_card_info? fun(self: any, info: hooks.OnCardInfoResult)
---@field on_shop_info? fun(self: any, info: hooks.OnShopInfoResult)
local Hooks = {}

---@param params vibes.effect.HookParams
---@return vibes.Hooks
function Hooks.new(params)
  return setmetatable(params, {
    __index = function()
      return function() end
    end,
  }) --[[@as vibes.Hooks]]
end

return Hooks
