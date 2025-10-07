---@diagnostic disable

--- AI strategy for consistent tower placement and card play decisions
--- Provides deterministic decision-making for simulation tests
---@class vibes.testing.AIStrategy
local AIStrategy = {}

--- Strategy for tower placement priorities
---@enum vibes.testing.PlacementStrategy
local PlacementStrategy = {
  ENTRANCE_FOCUS = "entrance_focus", -- Place towers near enemy spawn points
  EXIT_BLOCK = "exit_block", -- Place towers near the exit to catch stragglers
  PATH_CHOKE = "path_choke", -- Place towers at narrow points in the path
  BALANCED = "balanced", -- Mix of entrance and choke point placement
}

--- Current placement strategy
local current_strategy = PlacementStrategy.BALANCED

--- Set the AI placement strategy
---@param strategy vibes.testing.PlacementStrategy
function AIStrategy.set_placement_strategy(strategy) current_strategy = strategy end

--- Get the current placement strategy
---@return vibes.testing.PlacementStrategy
function AIStrategy.get_placement_strategy() return current_strategy end

--- Evaluate a cell for tower placement based on current strategy
---@param cell vibes.Cell
---@param level vibes.Level
---@return number score Higher scores indicate better placement locations
function AIStrategy.evaluate_cell_for_placement(cell, level)
  if not cell.is_placeable then
    return -1
  end

  local score = 0
  local cell_pos = cell:center()

  -- Get path information - simplified for now
  local paths = nil
  if level and level.paths then
    paths = level.paths
  end

  if not paths then
    -- Simple scoring: prefer cells closer to center
    local center_x = Config.grid.grid_width * Config.grid.cell_size / 2
    local center_y = Config.grid.grid_height * Config.grid.cell_size / 2
    local distance =
      math.sqrt((cell_pos.x - center_x) ^ 2 + (cell_pos.y - center_y) ^ 2)
    return math.max(0, 1000 - distance)
  end

  -- Strategic scoring: prioritize cells that can cover multiple path segments
  local total_path_score = 0
  local archer_range = 3.9 * Config.grid.cell_size -- Archer tower range: 3.9 cells * cell_size pixels

  for _, path in pairs(paths) do
    if path.cells and #path.cells > 0 then
      local path_coverage = 0

      -- Count how many path cells are within archer range
      for _, path_cell in ipairs(path.cells) do
        local path_pos = path_cell:center()
        local distance = cell_pos:distance(path_pos)

        if distance <= archer_range then
          -- Higher score for closer path cells
          path_coverage = path_coverage + math.max(0, archer_range - distance)
        end
      end

      -- Bonus for covering early path segments (where enemies spawn)
      local early_path_bonus = 0
      local early_segments = math.min(5, #path.cells) -- First 5 path cells
      for i = 1, early_segments do
        local path_cell = path.cells[i]
        local path_pos = path_cell:center()
        local distance = cell_pos:distance(path_pos)

        if distance <= archer_range then
          -- Extra bonus for early path coverage
          early_path_bonus = early_path_bonus + (archer_range - distance) * 2
        end
      end

      total_path_score = total_path_score + path_coverage + early_path_bonus
    end
  end

  score = total_path_score

  return score
end

--- Find the best cell for tower placement
---@param level vibes.Level
---@return vibes.Cell?
function AIStrategy.find_best_placement_cell(level)
  local best_cell = nil
  local best_score = -1

  -- Try to get cells from the level
  local cells = nil
  if level and level.cells then
    cells = level.cells
  elseif State and State.levels then
    local current_level = State.levels:get_current_level()
    if current_level and current_level.cells then
      cells = current_level.cells
    end
  end

  if not cells then
    logger.warn "AIStrategy: Could not find cells for placement"
    return nil
  end

  -- Find any placeable cell within the valid grid bounds
  -- Prioritize cells that are actually strategic for killing enemies
  for row = 1, Config.grid.grid_height do
    if cells[row] then
      for col = 1, Config.grid.grid_width do
        local cell = cells[row][col]
        if cell and cell.is_placeable then
          local score = AIStrategy.evaluate_cell_for_placement(cell, level)
          if score > best_score then
            best_score = score
            best_cell = cell
          end
        end
      end
    end
  end

  if best_cell then
    logger.debug(
      "AIStrategy: Found placement cell at row=%d, col=%d with score=%d",
      best_cell.row + 1,
      best_cell.col + 1,
      best_score
    )
  else
    logger.debug "AIStrategy: No placeable cells found"
  end

  return best_cell
end

--- Decide which card to play from hand
---@param hand vibes.Card[]
---@param game_state vibes.GameState
---@return vibes.Card? card The card to play, or nil if no good options
---@return vibes.Cell? target The target cell for tower cards
function AIStrategy.choose_card_to_play(hand, game_state)
  if not hand or #hand == 0 then
    logger.debug "AIStrategy: No cards in hand"
    return nil, nil
  end

  logger.debug("AIStrategy: Evaluating %d cards in hand", #hand)
  for i, card in ipairs(hand) do
    logger.debug(
      "AIStrategy: Card %d: name=%s, type=%s, kind=%s, energy=%s, tower=%s",
      i,
      card.name or "nil",
      card._type or "nil",
      card.kind or "nil",
      card.energy or "nil",
      card.tower and "yes" or "no"
    )
  end

  -- Priority order: Tower cards > Enhancement cards > Aura cards

  -- First, try to play tower cards if we have good placement spots
  for _, card in ipairs(hand) do
    if card and card.energy then
      local is_tower_card = false

      -- Check multiple ways to identify tower cards
      if card._type and card._type:match "TowerCard" then
        is_tower_card = true
      elseif card.kind == CardKind.TOWER then
        is_tower_card = true
      elseif card.tower then -- Direct tower reference
        is_tower_card = true
      end

      if is_tower_card and game_state.player.energy >= card.energy then
        local level = game_state.levels:get_current_level()
        local target_cell = AIStrategy.find_best_placement_cell(level)
        if target_cell then
          logger.debug(
            "AIStrategy: Choosing tower card %s (type: %s, kind: %s) for placement",
            card.name or "unknown",
            card._type or "unknown",
            card.kind or "unknown"
          )
          return card, target_cell
        else
          logger.debug(
            "AIStrategy: Found tower card %s but no valid placement cell",
            card.name or card._type or "unknown"
          )
        end
      end
    end
  end

  -- Next, try enhancement cards on existing towers
  for _, card in ipairs(hand) do
    if card and card.energy then
      local is_enhancement_card = false

      -- Check multiple ways to identify enhancement cards
      if card._type and card._type:match "EnhancementCard" then
        is_enhancement_card = true
      elseif card.kind == CardKind.ENHANCEMENT then
        is_enhancement_card = true
      end

      if
        is_enhancement_card
        and game_state.player.energy >= card.energy
        and game_state.towers
        and #game_state.towers > 0
      then
        -- Find the UI component for the first tower
        local tower = game_state.towers[1]
        local placed_tower = nil

        -- Try to find the placed tower UI component
        if GAME and GAME.ui and GAME.ui.find_placed_tower then
          placed_tower = GAME.ui:find_placed_tower(tower)
        end

        if placed_tower then
          logger.debug(
            "AIStrategy: Choosing enhancement card %s for tower",
            card.name or card._type
          )
          return card, placed_tower
        else
          logger.debug "AIStrategy: Could not find placed tower UI component for enhancement"
        end
      end
    end
  end

  -- Finally, try aura cards
  for _, card in ipairs(hand) do
    if card and card.energy then
      local is_aura_card = false

      -- Check multiple ways to identify aura cards
      if card._type and card._type:match "AuraCard" then
        is_aura_card = true
      elseif card.kind == CardKind.AURA then
        is_aura_card = true
      end

      if is_aura_card and game_state.player.energy >= card.energy then
        logger.debug(
          "AIStrategy: Choosing aura card %s",
          card.name or card._type
        )
        return card, nil
      end
    end
  end

  -- If we can't find any specific card types, just try the first playable card
  for _, card in ipairs(hand) do
    if card and card.energy and game_state.player.energy >= card.energy then
      logger.debug(
        "AIStrategy: Fallback - choosing any playable card %s",
        card.name or card._type or "unknown"
      )
      return card, nil
    end
  end

  return nil, nil
end

--- Decide which tower upgrade to choose
---@param upgrade_options tower.UpgradeOption[]
---@param tower vibes.Tower
---@return tower.UpgradeOption?
function AIStrategy.choose_tower_upgrade(upgrade_options, tower)
  if not upgrade_options or #upgrade_options == 0 then
    return nil
  end

  -- Simple strategy: prefer damage upgrades, then range, then attack speed
  local priorities = {
    damage = 3,
    range = 2,
    attack_speed = 1,
  }

  local best_option = nil
  local best_priority = -1

  for _, option in ipairs(upgrade_options) do
    -- This is a simplified approach - in reality you'd need to examine
    -- the upgrade option's effects more carefully
    local priority = 0

    -- Try to determine what this upgrade affects
    if option.name and option.name:lower():match "damage" then
      priority = priorities.damage or 0
    elseif option.name and option.name:lower():match "range" then
      priority = priorities.range or 0
    elseif
      option.name and option.name:lower():match "speed"
      or (option.name and option.name:lower():match "attack")
    then
      priority = priorities.attack_speed or 0
    else
      priority = 1 -- Default priority for unknown upgrades
    end

    if priority > best_priority then
      best_priority = priority
      best_option = option
    end
  end

  return best_option or upgrade_options[1] -- Fallback to first option
end

return AIStrategy
