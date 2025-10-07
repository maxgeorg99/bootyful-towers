local GameFunctions = require "vibes.data.game-functions"
local Gear = require "gear"

local M = {}

-- TJ: Checked
-- NOTE: Handled in GameState:damage_enemy
M.moustache_comb = Gear.new {
  name = "Moustache Comb",
  description = {
    "Critical hits deal {critical:1.5x} more damage",
  },
  texture = Asset.sprites.gear_moustache_comb,
  kind = GearKind.TOOL,
  rarity = Rarity.EPIC, -- Very powerful crit multiplier boost
  slot = nil,
  hooks = {},
}

-- TJ: Checked
M.fire_hat = Gear.new {
  name = "Fire Hat",
  description = { "Increases fire growth rate by {fire_growth:1} per tick" },
  texture = Asset.sprites.gear_fire_hat, -- Using fire orb sprite instead of placeholder
  kind = GearKind.HAT,
  rarity = Rarity.UNCOMMON, -- Situational but useful for fire builds
  slot = nil,
  hooks = {
    on_fire_tick = function(_, fire_state)
      fire_state.fire_growth = fire_state.fire_growth + 1
    end,
  },
}

-- TJ: Checked
M.tax_write_off = Gear.new {
  name = "TaxWriteOff",
  description = {
    "Reduces ALL energy costs by {energy_cost_reduction:1}",
  },
  texture = Asset.sprites.gear_tax_write_off,
  kind = GearKind.TOOL,
  rarity = Rarity.LEGENDARY, -- Very powerful economy effect
  slot = nil,

  ---@type vibes.effect.HookParams
  hooks = {
    on_card_info = function(_, event)
      event.modified_energy = math.max(0, event.modified_energy - 1)
    end,
  },
}

-- TJ: Checked
M.rubiks_cube = Gear.new {
  name = "Rubik's Cube",
  description = {
    "25% chance on tower attack to scramble enemy shields, reducing both shield and capacity by 50%.",
  },
  texture = Asset.sprites.gear_rubiks_cube,
  kind = GearKind.TOOL,
  rarity = Rarity.RARE,
  slot = nil,
  hooks = {
    on_tower_attack = function(_, _, enemy)
      -- 25% chance to scramble shields
      if math.random() <= 0.25 then
        local current_shield = enemy:get_shield()
        local current_capacity = enemy:get_shield_capacity()

        -- SCRAMBLE THE SHIELDS! Reduce both by 50%
        local new_capacity = math.floor(current_capacity * 0.5)
        local new_shield = math.floor(current_shield * 0.5)

        -- Apply the scramble effect
        enemy.stats_base.shield_capacity = Stat.new(new_capacity, 1)
        enemy.stats_base.shield = Stat.new(new_shield, 1)
        enemy.stats_manager:update()
      end
    end,
  },
}

-- TJ: Checked, missing art
M.spinner_hat = Gear.new {
  name = "Spinner Hat",
  description = {
    "Multiplies all tower attack speeds and upgrades by {attack_speed:30%}",
  },
  texture = Asset.sprites.gear_spinner_hat,
  kind = GearKind.HAT,
  rarity = Rarity.RARE, -- Strong global attack speed boost
  slot = nil,
  hooks = {},
  is_active_on_tower = function() return true end,
  get_tower_operations = function()
    return {
      TowerStatOperation.new {
        field = TowerStatField.ATTACK_SPEED,
        operation = StatOperation.new {
          kind = StatOperationKind.MUL_MULT,
          value = 1.3,
        },
      },
    }
  end,
}

-- TJ: Checked
M.split_keyboard = Gear.new {
  name = "Split Keyboard",
  description = { "All towers gain {enemy_targets:+1}" }, -- TODO: Description was confusing, clarified it affects all towers
  texture = Asset.sprites.gear_split_keyboard,
  kind = GearKind.TOOL,
  rarity = Rarity.EPIC, -- Very powerful effect for all towers
  slot = nil,
  hooks = {},
  is_active_on_tower = function() return true end,
  get_tower_operations = function()
    return {
      TowerStatOperation.new {
        field = TowerStatField.ENEMY_TARGETS,
        operation = StatOperation.new {
          kind = StatOperationKind.ADD_MULT,
          value = 1,
        },
      },
    }
  end,
}

-- TJ: Checked
M.top_hat = Gear.new {
  name = "Top Hat",
  description = {
    "Gain {gold:+1} per {gold:50} gold you have at wave end.",
  },
  texture = Asset.sprites.gear_top_hat,
  kind = GearKind.HAT,
  rarity = Rarity.UNCOMMON, -- Scaling compound interest is extremely powerful
  slot = nil,
  hooks = {
    after_wave_ends = function(_, wave)
      local current_gold = State.player.gold
      local interest = math.floor(current_gold / 50)

      if interest > 0 then
        State.player:gain_gold(interest)
      end
    end,
  },
}

-- TJ: Checked
M.energy_ring = Gear.new {
  name = "Energy Ring",
  description = { "Grants {energy_bonus:1} starting energy each wave" },
  texture = Asset.sprites.gear_energy_ring,
  kind = GearKind.RING,
  rarity = Rarity.UNCOMMON, -- Solid energy boost
  slot = nil,
  hooks = {
    before_playing_actions = function(_, result)
      result.energy = result.energy + 1
    end,
  },
}

-- TJ: Checked, Missing art
-- M.attack_speed_ring = Gear.new {
--   name = "Attack Speed Ring",
--   description = { "Tower attack speed increases {attack_speed:+0.10}" },
--   texture = Asset.sprites.gear_attack_speed_ring,
--   kind = GearKind.RING,
--   rarity = Rarity.COMMON, -- Good but not as strong as Spinner Hat
--   slot = nil,
--   hooks = {},
--   is_active_on_tower = function() return true end,
--   get_tower_operations = function()
--     return {
--       TowerStatOperation.new {
--         field = TowerStatField.ATTACK_SPEED,
--         operation = StatOperation.new {
--           kind = StatOperationKind.ADD_BASE,
--           value = 0.10,
--         },
--       },
--     }
--   end,
-- }

-- TJ: Checked
M.defense_ring = Gear.new {
  name = "Defense Ring",
  description = { "Reduce enemy damage by {damage:20%}" },
  texture = Asset.sprites.gear_defense_ring,
  kind = GearKind.RING,
  rarity = Rarity.COMMON,
  slot = nil,
  hooks = {},
  is_active_on_enemy = function() return true end,
  get_enemy_operations = function()
    return {
      EnemyStatOperation.new {
        field = EnemyStatField.DAMAGE,
        operation = StatOperation.new {
          kind = StatOperationKind.ADD_MULT,
          value = -0.20,
        },
      },
    }
  end,
}

-- TJ: Checked
M.health_ring = Gear.new {
  name = "Health Ring",
  description = { "Heals {health:+10} before each wave" },
  texture = Asset.sprites.gear_health_ring,
  kind = GearKind.RING,
  rarity = Rarity.COMMON, -- Simple health boost
  slot = nil,
  hooks = {
    before_wave_starts = function(_, wave)
      State.player.health = State.player.health + 10
    end,
  },
}

-- TJ: Checked
M.snakeskin_boots = Gear.new {
  name = "Snakeskin Boots",
  description = { "Increases poison growth by {poison_growth:1} per tick" },
  texture = Asset.sprites.gear_snakeskin_boots,
  kind = GearKind.SHOES,
  rarity = Rarity.UNCOMMON, -- Situational but useful for poison builds
  slot = nil,
  hooks = {
    on_poison_tick = function(_, poison_state)
      poison_state.poison_growth = poison_state.poison_growth + 1
    end,
  },
}

-- TJ: Checked
M.silk_shirt = Gear.new {
  name = "Silk Shirt",
  description = { "All purchases cost 20% more. Flex on the haters." },
  texture = Asset.sprites.gear_silk_shirt,
  kind = GearKind.SHIRT,
  rarity = Rarity.UNCOMMON,
  slot = nil,
  hooks = {
    on_shop_info = function(_, info) info.price = info.price * 1.2 end,
  },
}

-- TJ: Checked, missing art
M.heavy_boots = Gear.new {
  name = "Heavy Boots",
  description = { "All enemies move 10% slower." },
  texture = Asset.sprites.gear_heavy_boots,
  kind = GearKind.SHOES,
  rarity = Rarity.COMMON, -- Simple but useful speed reduction
  slot = nil,
  hooks = {},
  is_active_on_enemy = function() return true end,
  get_enemy_operations = function()
    return {
      EnemyStatOperation.new {
        field = EnemyStatField.SPEED,
        operation = StatOperation.new {
          kind = StatOperationKind.ADD_MULT,
          value = -0.10,
        },
      },
    }
  end,
}

-- DO NOT TOUCH! POINT CROW MADE IT!!!!
M.quiet_baby = Gear.new {
  name = "Quiet Baby!",
  description = { "Gives 50 gold when a level ends" }, -- TODO: Description formatting was unclear
  texture = Asset.sprites.gear_baby, -- TODO: Replace with actual texture
  kind = GearKind.TOOL,
  rarity = Rarity.UNCOMMON, -- Decent gold generation
  slot = nil,
  hooks = {
    after_level_end = function() State.player:gain_gold(50) end,
  },
}

-- M.tactician_manual = Gear.new {
--   name = "Tactician's Manual",
--   description = {
--     "Shield is current protection that blocks damage, Shield Capacity is max shield for regeneration.",
--     "Break high shields with burst damage, outlast low shields with fast attacks, use poison to bypass shields entirely.",
--     "+10% damage to all towers.",
--   },
--   texture = Asset.sprites.gear_baby, -- TODO: Add manual/book sprite
--   kind = GearKind.TOOL,
--   rarity = Rarity.COMMON, -- Educational + small damage boost
--   slot = nil,
--   hooks = {},
--   is_active_on_tower = function() return true end,
--   get_tower_operations = function()
--     return {
--       TowerStatOperation.new {
--         field = TowerStatField.DAMAGE,
--         operation = StatOperation.new {
--           kind = StatOperationKind.ADD_MULT,
--           value = 0.10, -- +10% damage
--         },
--       },
--     }
--   end,
-- }

-- TJ: Checked
-- CRIT-ACTIVATED GEAR - BB AND BASH'S CHOICE LEGENDARY COLLECTION
M.chaos_crown = Gear.new {
  name = "Chaos Crown",
  description = {
    "On crit: Random tower gets +1 damage permanently. CHAOS REIGNS!",
  },
  texture = Asset.sprites.gear_chaos_crown,
  kind = GearKind.HAT,
  rarity = Rarity.LEGENDARY, -- Permanent scaling damage is extremely powerful
  slot = nil,
  hooks = {
    on_tower_critical_hit = function()
      -- Pick a random tower and give it permanent damage
      if #State.towers > 0 then
        local random_tower = State.towers[math.random(#State.towers)]
        local damage_op = TowerStatOperation.new {
          field = TowerStatField.DAMAGE,
          operation = StatOperation.new {
            kind = StatOperationKind.ADD_BASE,
            value = 1,
          },
        }
        damage_op:apply_to_tower_stats(random_tower.stats_base)
        random_tower.stats_manager:update()
      end
    end,
  },
}

-- TJ: Checked
M.hot_potato = Gear.new {
  name = "Hot Potato",
  description = {
    "When a burning enemy crosses another enemy without burn, spreads {burn_stacks:15} burn stacks to the non-burning enemy.",
  },
  texture = Asset.sprites.gear_potato, -- Using potato sprite as base
  kind = GearKind.TOOL,
  rarity = Rarity.RARE, -- Powerful spreading mechanic
  slot = nil,
  hooks = {
    on_fire_tick = function(_, fire_state)
      -- Check all burning enemies for nearby non-burning enemies
      for _, enemy in ipairs(State.enemies) do
        if enemy.fire_stacks > 0 then
          -- Find nearby enemies within a small radius (about 1.2 cells)
          local nearby_enemies =
            GameFunctions.enemies_within(enemy.position, 1.2)

          for _, nearby_enemy in ipairs(nearby_enemies) do
            -- Don't spread to self or enemies that already have burn
            if
              nearby_enemy.id ~= enemy.id and nearby_enemy.fire_stacks <= 0
            then
              -- HOT POTATO SPREAD! Apply 15 burn stacks
              nearby_enemy:apply_fire_stack(nil, 15)

              logger.info(
                "Hot Potato: Spread burn from %s to %s! Applied 15 fire stacks.",
                enemy.enemy_type,
                nearby_enemy.enemy_type
              )

              -- Visual feedback
              UI:create_user_message "HOT POTATO SPREAD!"

              -- Only spread to one enemy per burning enemy per tick to avoid chain reactions
              break
            end
          end
        end
      end
    end,
  },
}

-- New gear items
M.water_pollution = Gear.new {
  name = "Water Pollution",
  description = { "+8 damage multiplier on orcas" },
  texture = Asset.sprites.gear_water_pollution,
  kind = GearKind.TOOL,
  rarity = Rarity.COMMON,
  slot = nil,
  hooks = {},
  is_active_on_enemy = function(_, enemy)
    -- Only active on orca enemies
    return enemy.enemy_type == EnemyType.ORCA
  end,
  get_enemy_operations = function(_, enemy)
    if enemy.enemy_type == EnemyType.ORCA then
      return {
        EnemyStatOperation.new {
          field = EnemyStatField.DAMAGE, -- Increases damage taken by orcas
          operation = StatOperation.new {
            kind = StatOperationKind.ADD_MULT,
            value = 8.0, -- +8 damage multiplier
          },
        },
      }
    end
    return {}
  end,
}

M.gravity = Gear.new {
  name = "Gravity",
  description = { "10% speed reduction on flying stuff" },
  texture = Asset.sprites.gear_rubiks_cube, -- TODO: Add gravity specific sprite
  kind = GearKind.TOOL,
  rarity = Rarity.COMMON,
  slot = nil,
  hooks = {},
  is_active_on_enemy = function(_, enemy)
    -- Only active on flying enemies (bats and wyvern)
    return enemy.enemy_type == EnemyType.BAT
      or enemy.enemy_type == EnemyType.BAT_ELITE
      or enemy.enemy_type == EnemyType.WYVERN
  end,
  get_enemy_operations = function(_, enemy)
    if
      enemy.enemy_type == EnemyType.BAT
      or enemy.enemy_type == EnemyType.BAT_ELITE
      or enemy.enemy_type == EnemyType.WYVERN
    then
      return {
        EnemyStatOperation.new {
          field = EnemyStatField.SPEED,
          operation = StatOperation.new {
            kind = StatOperationKind.MUL_MULT,
            value = 0.90, -- 10% speed reduction
          },
        },
      }
    end
    return {}
  end,
}

M.trashs_wine = Gear.new {
  name = "Trash's Wine",
  description = {
    "Becomes $3 more valuable after every round when equipped.",
  },
  texture = Asset.sprites.gear_wine,
  kind = GearKind.TOOL,
  rarity = Rarity.COMMON,
  slot = nil,

  get_selling_price = function(self, price)
    return (self._trashs_wine_value or 0) + price
  end,

  hooks = {
    before_wave_starts = function(self, wave)
      self._trashs_wine_value = (self._trashs_wine_value or 0) + 3
    end,
  },
}

M.trashs_chips = Gear.new {
  name = "Trash's Chips",
  description = {
    "Gives 5 HP at the end of each wave. If wine is also equipped, gives 8 HP per wave instead.",
  },
  texture = Asset.sprites.gear_chips,
  kind = GearKind.TOOL,
  rarity = Rarity.COMMON,
  slot = nil,
  hooks = {
    after_wave_ends = function()
      local has_wine = State.gear_manager:has_gear(M.trashs_wine)
      local hp_gain = has_wine and 8 or 5
      State.player:heal(hp_gain)
    end,
  },
}

M.sunflower = Gear.new {
  name = "Sunflower",
  description = {
    "1x damage multiplier until level 4 tower, 1.5x until level 5 tower, 8x when level 6 tower and beyond",
  },
  texture = Asset.sprites.gear_sunflower,
  kind = GearKind.TOOL,
  rarity = Rarity.COMMON,
  slot = nil,
  hooks = {},
  is_active_on_tower = function(_, tower)
    -- Active on all towers to provide level-based multipliers
    return true
  end,
  get_tower_operations = function(_, tower)
    local multiplier = 1.0 -- Default 1x multiplier

    if tower.level >= 6 then
      multiplier = 8.0 -- 8x multiplier for level 6+
    elseif tower.level >= 5 then
      multiplier = 1.5 -- 1.5x multiplier for level 5
    else
      multiplier = 1.0 -- 1x multiplier for levels 1-4
    end

    return {
      TowerStatOperation.new {
        field = TowerStatField.DAMAGE,
        operation = StatOperation.new {
          kind = StatOperationKind.MUL_MULT,
          value = multiplier,
        },
      },
    }
  end,
}

M.strong_tearaway_pants = Gear.new {
  name = "Strong Tearaway pants",
  description = { "3x stats damage on last wave" },
  texture = Asset.sprites.gear_strong_tearaway_pants,
  kind = GearKind.PANTS,
  rarity = Rarity.UNCOMMON,
  slot = nil,
  hooks = {},
  is_active_on_tower = function(_, tower)
    -- Only active on last regular wave of the level
    local current_wave = State.levels.current_wave
    local level = State.levels:get_current_level()
    local total_waves = level and level.waves and #level.waves or 3
    local is_last_regular_wave = current_wave == total_waves
    return is_last_regular_wave
  end,
  get_tower_operations = function(_, tower)
    local current_wave = State.levels.current_wave
    local level = State.levels:get_current_level()
    local total_waves = level and level.waves and #level.waves or 3
    local is_last_regular_wave = current_wave == total_waves

    if is_last_regular_wave then
      return {
        TowerStatOperation.new {
          field = TowerStatField.DAMAGE,
          operation = StatOperation.new {
            kind = StatOperationKind.MUL_MULT,
            value = 3.0, -- 3x damage multiplier on last regular wave
          },
        },
      }
    end
    return {}
  end,
}

M.reinforced_tearaway_pants = Gear.new {
  name = "Reinforced Tearaway pants",
  description = { "3x stats critical hit rate on last wave" },
  texture = Asset.sprites.gear_tearaway_pants,
  kind = GearKind.PANTS,
  rarity = Rarity.UNCOMMON,
  slot = nil,
  hooks = {},
  is_active_on_tower = function(_, tower)
    -- Only active on last regular wave of the level
    local current_wave = State.levels.current_wave
    local level = State.levels:get_current_level()
    local total_waves = level and level.waves and #level.waves or 3
    local is_last_regular_wave = current_wave == total_waves
    return is_last_regular_wave
  end,
  get_tower_operations = function(_, tower)
    local current_wave = State.levels.current_wave
    local level = State.levels:get_current_level()
    local total_waves = level and level.waves and #level.waves or 3
    local is_last_regular_wave = current_wave == total_waves

    if is_last_regular_wave then
      return {
        TowerStatOperation.new {
          field = TowerStatField.CRITICAL,
          operation = StatOperation.new {
            kind = StatOperationKind.MUL_MULT,
            value = 3.0, -- 3x critical hit rate multiplier on last regular wave
          },
        },
      }
    end
    return {}
  end,
}

M.second_wind_pants = Gear.new {
  name = "Second Wind pants",
  description = { "3x stats speed on last wave" },
  texture = Asset.sprites.gear_second_wind_pants,
  kind = GearKind.PANTS, -- Fixed: should be pants, not shoes
  rarity = Rarity.UNCOMMON,
  slot = nil,
  hooks = {},
  is_active_on_tower = function(_, tower)
    -- Only active on last regular wave of the level
    local current_wave = State.levels.current_wave
    local level = State.levels:get_current_level()
    local total_waves = level and level.waves and #level.waves or 3
    local is_last_regular_wave = current_wave == total_waves
    return is_last_regular_wave
  end,
  get_tower_operations = function(_, tower)
    local current_wave = State.levels.current_wave
    local level = State.levels:get_current_level()
    local total_waves = level and level.waves and #level.waves or 3
    local is_last_regular_wave = current_wave == total_waves

    if is_last_regular_wave then
      return {
        TowerStatOperation.new {
          field = TowerStatField.ATTACK_SPEED,
          operation = StatOperation.new {
            kind = StatOperationKind.MUL_MULT,
            value = 3.0, -- 3x attack speed multiplier on last regular wave
          },
        },
      }
    end
    return {}
  end,
}

return M
