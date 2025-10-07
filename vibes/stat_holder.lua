---@class vibes.StatHolder
---@field new fun(): vibes.StatHolder
---@field total_damage_dealt number
---@field total_enemies_killed number
---@field total_damage_enemy_blocked number
---@field total_damage_by_kind { [DamageKind]: number }
---@field total_cards_played number
---@field total_cards_drawn number
---@field total_cards_discarded number
---@field total_cards_exhausted number
---@field total_cards_gained number
---@field total_gold_spent number
---@field total_towers_placed number
---@field total_tower_upgrades number
---@field total_tower_stat_upgrades number
---@field total_tower_evolutions number
---@field total_critical_hits number
---@field total_critical_damage number
---@field total_player_damage_taken number
---@field total_player_damage_blocked number
---@field total_player_block_gained number
---@field total_enemies_reached_end number
---@field total_discards_used number
local StatHolder = class "vibes.StatHolder"

function StatHolder:init()
  self.total_damage_dealt = 0
  self.total_enemies_killed = 0
  self.total_damage_enemy_blocked = 0
  self.total_damage_by_kind = {}
  self.total_cards_played = 0
  self.total_cards_drawn = 0
  self.total_cards_discarded = 0
  self.total_cards_exhausted = 0
  self.total_cards_gained = 0
  self.total_gold_spent = 0
  self.total_towers_placed = 0
  self.total_tower_upgrades = 0
  self.total_tower_stat_upgrades = 0
  self.total_tower_evolutions = 0
  self.total_critical_hits = 0
  self.total_critical_damage = 0
  self.total_player_damage_taken = 0
  self.total_player_damage_blocked = 0
  self.total_player_block_gained = 0
  self.total_enemies_reached_end = 0
  self.total_discards_used = 0

  -- Set up event listeners
  self:_setup_event_listeners()
end

function StatHolder:reset()
  self.total_damage_dealt = 0
  self.total_enemies_killed = 0
  self.total_damage_enemy_blocked = 0
  self.total_damage_by_kind = {}
  self.total_cards_played = 0
  self.total_cards_drawn = 0
  self.total_cards_discarded = 0
  self.total_cards_exhausted = 0
  self.total_cards_gained = 0
  self.total_gold_spent = 0
  self.total_towers_placed = 0
  self.total_tower_upgrades = 0
  self.total_tower_stat_upgrades = 0
  self.total_tower_evolutions = 0
  self.total_critical_hits = 0
  self.total_critical_damage = 0
  self.total_player_damage_taken = 0
  self.total_player_damage_blocked = 0
  self.total_player_block_gained = 0
  self.total_enemies_reached_end = 0
  self.total_discards_used = 0
end

--- Set up event listeners to track stats
function StatHolder:_setup_event_listeners()
  self._disposers = {}

  -- Track damage dealt to enemies
  table.insert(
    self._disposers,
    EventBus:listen_enemy_damage(function(event)
      self.total_damage_dealt = self.total_damage_dealt + event.damage

      -- Track damage by kind
      local kind = event.kind
      if not self.total_damage_by_kind[kind] then
        self.total_damage_by_kind[kind] = 0
      end
      self.total_damage_by_kind[kind] = self.total_damage_by_kind[kind]
        + event.damage
    end)
  )

  -- Track enemy deaths
  table.insert(
    self._disposers,
    EventBus:listen_enemy_death(
      function(event) self.total_enemies_killed = self.total_enemies_killed + 1 end
    )
  )

  -- Track blocked damage
  table.insert(
    self._disposers,
    EventBus:listen_enemy_blocked_damage(
      function(event)
        self.total_damage_enemy_blocked = self.total_damage_enemy_blocked
          + event.blocked
      end
    )
  )

  -- Track cards played
  table.insert(
    self._disposers,
    EventBus:listen_card_played(
      function(event) self.total_cards_played = self.total_cards_played + 1 end
    )
  )

  -- Track cards drawn
  table.insert(
    self._disposers,
    EventBus:listen_card_draw(
      function(event) self.total_cards_drawn = self.total_cards_drawn + 1 end
    )
  )

  -- Track cards discarded
  table.insert(
    self._disposers,
    EventBus:listen_card_discard(
      function(event)
        self.total_cards_discarded = self.total_cards_discarded + 1
      end
    )
  )

  -- Track cards exhausted
  table.insert(
    self._disposers,
    EventBus:listen_card_exhaust(
      function(event)
        self.total_cards_exhausted = self.total_cards_exhausted + 1
      end
    )
  )

  -- Track cards gained
  table.insert(
    self._disposers,
    EventBus:listen_card_gained(
      function(event) self.total_cards_gained = self.total_cards_gained + 1 end
    )
  )

  -- Track gold spent
  table.insert(
    self._disposers,
    EventBus:listen_spend_gold(
      function(event) self.total_gold_spent = self.total_gold_spent + event.gold end
    )
  )

  -- Track towers placed
  table.insert(
    self._disposers,
    EventBus:listen_tower_placed(
      function(event) self.total_towers_placed = self.total_towers_placed + 1 end
    )
  )

  -- Track tower upgrades
  table.insert(
    self._disposers,
    EventBus:listen_tower_upgrade_selected(
      function(event) self.total_tower_upgrades = self.total_tower_upgrades + 1 end
    )
  )

  -- Track tower stat upgrades (includes both upgrades and evolutions)
  table.insert(
    self._disposers,
    EventBus:listen_tower_stat_upgrade(function(event)
      self.total_tower_stat_upgrades = self.total_tower_stat_upgrades + 1

      -- Check if this is an evolution (EvolutionOption vs UpgradeOption)
      if
        event.upgrade
        and event.upgrade._type
        and event.upgrade._type:find "Evolution"
      then
        self.total_tower_evolutions = self.total_tower_evolutions + 1
      end
    end)
  )

  -- Track critical hits
  table.insert(
    self._disposers,
    EventBus:listen_tower_critical_hit(function(event)
      self.total_critical_hits = self.total_critical_hits
        + event.crits_triggered
      self.total_critical_damage = self.total_critical_damage
        + event.critical_damage
    end)
  )

  -- Track player damage taken
  table.insert(
    self._disposers,
    EventBus:listen_player_damage_taken(
      function(event)
        self.total_player_damage_taken = self.total_player_damage_taken
          + event.damage
      end
    )
  )

  -- Track player damage blocked
  table.insert(
    self._disposers,
    EventBus:listen_player_damage_blocked(
      function(event)
        self.total_player_damage_blocked = self.total_player_damage_blocked
          + event.damage_blocked
      end
    )
  )

  -- Track player block gained
  table.insert(
    self._disposers,
    EventBus:listen_player_block_gained(
      function(event)
        self.total_player_block_gained = self.total_player_block_gained
          + event.block
      end
    )
  )

  -- Track enemies that reached the end
  table.insert(
    self._disposers,
    EventBus:listen_enemy_reached_end(
      function(event)
        self.total_enemies_reached_end = self.total_enemies_reached_end + 1
      end
    )
  )

  -- Track discards used
  table.insert(
    self._disposers,
    EventBus:listen_player_discard_used(
      function(event)
        self.total_discards_used = self.total_discards_used
          + event.discards_used
      end
    )
  )
end

--- Clean up event listeners
function StatHolder:cleanup()
  if self._disposers then
    for _, disposer in ipairs(self._disposers) do
      disposer()
    end
    self._disposers = {}
  end
end

return StatHolder
