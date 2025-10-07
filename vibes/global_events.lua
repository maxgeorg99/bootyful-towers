EventBus:listen_enemy_spawned(function(event)
  ---@type hook.AfterEnemySpawn.Opts
  local params = { enemy = event.enemy }

  State:for_each_active_hook(
    function(item) item.hooks.after_enemy_spawn(item, params) end
  )
end)

EventBus:listen_enemy_death(function(event)
  ---@cast event vibes.event.EnemyDeath
  local enemy = event.enemy

  GameAnimationSystem:play_death_coin(enemy.position:clone())
  State.player.gold = State.player.gold + enemy.gold_reward

  if event.kind == DamageKind.POISON then
    local total_sources = 0
    for _, damage in pairs(enemy.poison_stack_sources) do
      total_sources = total_sources + damage
    end

    for tower, damage in pairs(enemy.poison_stack_sources) do
      tower:apply_experience_for_damage(
        damage / total_sources * enemy.xp_reward
      )
    end

    -- On Death Hooks from enemy status
    if enemy.statuses.poison_pool then
      PoisonPoolSystem:spawn_pool(enemy.position)
    end
  elseif event.kind == DamageKind.FIRE then
    local total_sources = 0
    for _, damage in pairs(enemy.fire_stack_sources) do
      total_sources = total_sources + damage
    end

    for tower, damage in pairs(enemy.fire_stack_sources) do
      tower:apply_experience_for_damage(
        damage / total_sources * enemy.xp_reward
      )
    end
  elseif
    event.kind == DamageKind.PHYSICAL or event.kind == DamageKind.WATER
  then
    assert(event.tower, "Physical damage must have a tower")

    if event.tower then
      event.tower:apply_experience_for_kill(enemy)
    end
  end

  State:for_each_active_hook(
    function(item) item.hooks.after_enemy_death(item, enemy) end
  )

  State:remove_enemy(enemy)
end)

EventBus:listen_enemy_reached_end(function(event)
  ---@cast event vibes.event.EnemyReachedEnd
  local enemy = event.enemy

  local damage = enemy:get_damage()
  State.player:take_damage(damage)
  State:remove_enemy(enemy)
end)

EventBus:listen_card_draw(function(event)
  if not event.card then
    return
  end

  ---@cast event vibes.event.DrawCard
  local card = event.card

  State:for_each_active_hook(
    function(item) item.hooks.on_card_drawn(item, card) end
  )

  if card.hooks and card.hooks.on_card_drawn then
    card.hooks.on_card_drawn(card, card)
  end
end)

EventBus:listen_card_discard(function(event)
  if not event.card then
    return
  end

  ---@cast event vibes.event.DiscardCard
  local card = event.card

  State:for_each_active_hook(
    function(item) item.hooks.on_card_discarded(item, card) end
  )

  if card.hooks and card.hooks.on_card_discarded then
    card.hooks.on_card_discarded(card, card)
  end
end)

EventBus:listen_card_played(function(event)
  if not event.card then
    return
  end

  -- TODO: Would be cool to play this as part of the hooks in the card.
  local DamEnhancement = require "vibes.card.enhancement.dam"
  if DamEnhancement.is(event.card) then
    local card = event.card --[[@as enhancement.Dam]]
    card.is_played = true
  end
end)

EventBus:listen_after_level_end(function(event)
  State:for_each_active_hook(
    function(item) item.hooks.after_level_end(item, event) end,
    { all_cards = true }
  )
end)

EventBus:listen_after_level_end(function(event)
  -- Reset the player state after level end
  State.player:set_block(0)

  SpeedManager:set_speed(1)
end)

EventBus:listen_tower_upgrade_menu_opened(
  function(_) SpeedManager:set_temp_speed(0.25) end
)

EventBus:listen_tower_upgrade_menu_closed(
  function(_) SpeedManager:restore_speed() end
)

EventBus:listen_tower_critical_hit(function(event)
  ---@cast event vibes.event.TowerCriticalHit
  local params = {
    tower = event.tower,
    enemy = event.enemy,
    base_damage = event.base_damage,
    critical_damage = event.critical_damage,
    crits_triggered = event.crits_triggered,
  }

  State:for_each_active_hook(
    function(item) item.hooks.on_tower_critical_hit(item, params) end
  )
end)

EventBus:listen_tower_stat_upgrade(function(event)
  local TowerUpgradeAnimation =
    require "ui.components.tower.elements.upgrade-animation"

  local upgrade_animation = TowerUpgradeAnimation.new {
    tower = event.tower,
    upgrade = event.upgrade,
  }

  -- Add to game UI so it renders in the game world
  UI.root:append_child(upgrade_animation)
end)
