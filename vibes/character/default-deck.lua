local Archer = require "vibes.card.card-tower-archer"
local AttackSpeedCard = require "vibes.card.enhancement.attack-speed"
local Catapault = require "vibes.card.card-tower-catapault"
local CriticalCard = require "vibes.card.enhancement.critical"
local DamageCard = require "vibes.card.enhancement.damage"
local Deck = require "vibes.deck"
local GoldenHarvestCard = require "vibes.card.aura.golden-harvest"
local RangeCard = require "vibes.card.enhancement.range"
local ZombieHands = require "vibes.card.card-tower-zombie-hands"

local default_decks = {}

default_decks[CharacterKind.BLACKSMITH] = function()
  local deck = Deck.new()

  local archer = require "vibes.card.card-tower-archer"
  deck:add_card(archer.new { rarity = Rarity.COMMON })
  deck:add_card(archer.new { rarity = Rarity.COMMON })
  deck:add_card(archer.new { rarity = Rarity.COMMON })

  deck:add_card(DamageCard.new { rarity = Rarity.UNCOMMON })
  deck:add_card(DamageCard.new { rarity = Rarity.UNCOMMON })
  deck:add_card(CriticalCard.new { rarity = Rarity.UNCOMMON })
  deck:add_card(CriticalCard.new { rarity = Rarity.UNCOMMON })
  deck:add_card(RangeCard.new { rarity = Rarity.UNCOMMON })
  deck:add_card(RangeCard.new { rarity = Rarity.UNCOMMON })
  deck:add_card(AttackSpeedCard.new { rarity = Rarity.UNCOMMON })
  deck:add_card(Catapault.new {})



  --
  --
  --
  --
  --

  -- TJ TESTING {{{
  -- deck:add_card(
  --   require("vibes.card.card-tower-windmill").new { rarity = Rarity.COMMON }
  -- )
  -- local BurndownCard = require "vibes.card.enhancement.burndown"
  -- deck:add_card(BurndownCard.new())
  -- deck:add_card(
  --   require("vibes.card.card-tower-five-g").new { rarity = Rarity.UNCOMMON }
  -- )
  -- Only add ZombieHands card if surprise mode is enabled
  -- deck:add_card(ZombieHands.new())
  -- deck:add_card(
  --   require("vibes.card.card-tower-zombie-hands").new { rarity = Rarity.UNCOMMON }
  -- )
  -- deck:add_card(
  --   require("vibes.card.card-tower-zombie-hands").new { rarity = Rarity.UNCOMMON }
  -- )
  -- local TarTower = require "vibes.card.card-tower-tar"
  -- deck:add_card(TarTower.new { rarity = Rarity.UNCOMMON })
  -- deck:add_card(TarTower.new { rarity = Rarity.UNCOMMON })
  -- deck:add_card(TarTower.new { rarity = Rarity.UNCOMMON })
  -- deck:add_card(TarTower.new { rarity = Rarity.UNCOMMON })

  -- deck:add_card(DamageCard.new { rarity = Rarity.UNCOMMON })
  -- deck:add_card(DamageCard.new { rarity = Rarity.UNCOMMON })
  -- deck:add_card(DamageCard.new { rarity = Rarity.UNCOMMON })
  -- deck:add_card(DamageCard.new { rarity = Rarity.UNCOMMON })

  -- TJ TESTING }}}

  return deck
end

-- default_decks[CharacterKind.BLACKSMITH] = function() return Deck.new() end
default_decks[CharacterKind.MAGE] = function() return Deck.new() end
default_decks[CharacterKind.FUTURIST] = function() return Deck.new() end

return default_decks
