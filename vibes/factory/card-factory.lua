local pick_based_on_roll = require("vibes.weights").pick_based_on_roll
local Random = require "vibes.engine.random"

local random = {
  tower = Random.new { name = "card-factory-tower" },
  enhancement = Random.new { name = "card-factory-enhancement" },
  aura = Random.new { name = "card-factory-aura" },
  general = Random.new { name = "card-factory-general" },
}

local CardFactory = {}

-- Generate a card that is valid for the trophy room, which
-- is only aura's or enhancements
--- Generate a trophy card, randomly choosing between Aura and Enhancement based on their weights
---@return vibes.Card
function CardFactory.new_trophy_card()
  -- Define the weights for each kind
  local kind_weights = {
    [CardKind.AURA] = State.kind_weights and State.kind_weights[CardKind.AURA]
      or 1,
    [CardKind.ENHANCEMENT] = State.kind_weights
        and State.kind_weights[CardKind.ENHANCEMENT]
      or 1,
  }

  -- Calculate total weight
  local total_weight = 0
  for _, w in pairs(kind_weights) do
    total_weight = total_weight + w
  end

  -- Roll to pick kind
  local roll = random.general:random() * total_weight
  local acc = 0
  local chosen_kind = CardKind.ENHANCEMENT -- fallback
  for kind, w in pairs(kind_weights) do
    acc = acc + w
    if roll <= acc then
      chosen_kind = kind
      break
    end
  end

  -- Use the appropriate random generator for the chosen kind
  local rng = chosen_kind == CardKind.AURA and random.aura or random.enhancement
  local rarity_weights = State.card_rarity[chosen_kind]
  local rarity_roll = rng:random()
  local rarity = pick_based_on_roll(rarity_roll, rarity_weights)
  local level_roll = rng:random()

  return require("vibes.state.cards").get_card(chosen_kind, rarity, level_roll)
end

--- Generate a tower card using proper state-based rarity weights
---@return vibes.Card
function CardFactory.new_tower_card()
  local weights = State.card_rarity[CardKind.TOWER]
  local rarity_roll = random.tower:random()
  local rarity = pick_based_on_roll(rarity_roll, weights)

  local level_roll = random.tower:random()

  return require("vibes.state.cards").get_card(
    CardKind.TOWER,
    rarity,
    level_roll
  )
end

--- Generate an enhancement card using proper state-based rarity weights
---@return vibes.Card
function CardFactory.new_enhancement_card()
  local weights = State.card_rarity[CardKind.ENHANCEMENT]
  local rarity_roll = random.enhancement:random()
  local rarity = pick_based_on_roll(rarity_roll, weights)

  local level_roll = random.enhancement:random()

  return require("vibes.state.cards").get_card(
    CardKind.ENHANCEMENT,
    rarity,
    level_roll
  )
end

--- Generate an aura card using proper state-based rarity weights
---@return vibes.Card
function CardFactory.new_aura_card()
  local weights = State.card_rarity[CardKind.AURA]
  local rarity_roll = random.aura:random()
  local rarity = pick_based_on_roll(rarity_roll, weights)

  local level_roll = random.aura:random()

  return require("vibes.state.cards").get_card(
    CardKind.AURA,
    rarity,
    level_roll
  )
end

--- Get a random card of a specific type
---@param kind CardKind
---@return vibes.Card
function CardFactory.get_random_card(kind)
  if kind == CardKind.TOWER then
    return CardFactory.new_tower_card()
  elseif kind == CardKind.ENHANCEMENT then
    return CardFactory.new_enhancement_card()
  elseif kind == CardKind.AURA then
    return CardFactory.new_aura_card()
  else
    error("Unknown card kind: " .. tostring(kind))
  end
end

--- Generate a card of a specific rarity
---@param rarity Rarity
---@return vibes.Card
function CardFactory.get_card_by_rarity(rarity)
  local level_roll = random.general:random()
  local kind_roll = random.general:random()
  local kind = pick_based_on_roll(kind_roll, State.kind_weights)
  return require("vibes.state.cards").get_card(kind, rarity, level_roll)
end

--- Generate a trophy card of a specific rarity (excludes towers, only auras and enhancements)
---@param rarity Rarity
---@return vibes.Card
function CardFactory.get_trophy_card_by_rarity(rarity)
  -- Define the weights for each kind (same logic as new_trophy_card)
  local kind_weights = {
    [CardKind.AURA] = State.kind_weights and State.kind_weights[CardKind.AURA]
      or 1,
    [CardKind.ENHANCEMENT] = State.kind_weights
        and State.kind_weights[CardKind.ENHANCEMENT]
      or 1,
  }

  -- Calculate total weight
  local total_weight = 0
  for _, w in pairs(kind_weights) do
    total_weight = total_weight + w
  end

  -- Roll to pick kind
  local roll = random.general:random() * total_weight
  local acc = 0
  local chosen_kind = CardKind.ENHANCEMENT -- fallback
  for kind, w in pairs(kind_weights) do
    acc = acc + w
    if roll <= acc then
      chosen_kind = kind
      break
    end
  end

  local level_roll = random.general:random()
  return require("vibes.state.cards").get_card(chosen_kind, rarity, level_roll)
end

--- Get a random card of any type using overall kind weights
---@return vibes.Card
function CardFactory.random_card()
  local kind_roll = random.general:random()
  local kind = pick_based_on_roll(kind_roll, State.kind_weights)

  return CardFactory.get_random_card(kind)
end

return CardFactory
