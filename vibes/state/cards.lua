local AttackSpeedCard = require "vibes.card.enhancement.attack-speed"
local BunnisWrath = require "vibes.card.enhancement.bunnis-wrath"
local CriticalCard = require "vibes.card.enhancement.critical"
local DamageCard = require "vibes.card.enhancement.damage"
local Random = require "vibes.engine.random"
local RangeCard = require "vibes.card.enhancement.range"

local random = {
  [CardKind.TOWER] = Random.new { name = "card-tower" },
  [CardKind.ENHANCEMENT] = Random.new { name = "card-enhancement" },
  [CardKind.AURA] = Random.new { name = "card-aura" },
}

local function damage(rarity)
  return {
    card = function() return DamageCard.new { rarity = rarity } end,
    level = { min = 1, max = 1 },
  }
end

local function range(rarity)
  return {
    card = function() return RangeCard.new { rarity = rarity } end,
    level = { min = 1, max = 1 },
  }
end

local function attack_speed(rarity)
  return {
    card = function() return AttackSpeedCard.new { rarity = rarity } end,
    level = { min = 1, max = 1 },
  }
end

local function critical(rarity)
  return {
    card = function() return CriticalCard.new { rarity = rarity } end,
    level = { min = 1, max = 1 },
  }
end

local cards = {}

---@class (exact) vibes.cards.CardRoll
---@field card any
---@field level? { min: number, max: number }

-- TowersRarity
local archer_tower = require "vibes.card.card-tower-archer"
local captcha_tower = require "vibes.card.card-tower-captcha"
local tar_tower = require "vibes.card.card-tower-tar"


cards[CardKind.TOWER] = {
  [Rarity.COMMON] = {
    {
      card = archer_tower.new,
      level = { min = 1, max = 1 },
    },
    {
      card = require("vibes.card.card-tower-earth").new,
      level = { min = 1, max = 1 },
    },
  },
  [Rarity.UNCOMMON] = {
    {
      card = archer_tower.new,
      level = { min = 2, max = 3 },
    },
    {
      card = require("vibes.card.card-tower-catapault").new,
      level = { min = 1, max = 1 },
    },
    {
      card = tar_tower.new,
      level = { min = 1, max = 1 },
    },
    {
      card = require("vibes.card.card-tower-water").new,
      level = { min = 1, max = 1 },
    },
    {
      card = require("vibes.card.card-tower-five-g").new,
      level = { min = 1, max = 1 },
    },
    {
      card = require("vibes.card.card-tower-windmill").new,
      level = { min = 1, max = 1 },
    },
    {
      card = require("vibes.card.card-tower-zombie-hands").new,
      level = { min = 1, max = 1 },
    },
  },
  [Rarity.RARE] = {
    {
      card = require("vibes.card.card-tower-poisoned-arrow").new,
      level = { min = 1, max = 1 },
    },
    {
      card = captcha_tower.new,
      level = { min = 1, max = 1 },
    },
  },
  [Rarity.EPIC] = {
    {
      card = require("vibes.card.card-tower-emberwatch").new,
      level = { min = 1, max = 1 },
    },
  },
  [Rarity.LEGENDARY] = {
    {
      card = require("vibes.card.card-tower-money").new,
      level = { min = 1, max = 1 },
    },
  },
}

cards[CardKind.AURA] = {
  [Rarity.COMMON] = {
    {
      card = require("vibes.card.aura.little-apple").new,
    },
    {
      card = require("vibes.card.aura.go-fish").new,
    },
  },
  [Rarity.UNCOMMON] = {
    {
      card = require("vibes.card.aura.golden-harvest").new,
    },
    -- {
    --   card = require("vibes.card.aura.reinforcements").new,
    -- },
    {
      card = require("vibes.card.aura.git-stash").new,
    },
    {
      card = require("vibes.card.aura.hot-feet").new,
    },
    {
      card = require("vibes.card.aura.shooting-the-breeze").new,
    },
  },
  [Rarity.RARE] = {
    {
      card = require("vibes.card.aura.monster-energy").new,
    },
    {
      card = require("vibes.card.aura.leaky-stein").new,
    },
  },
  [Rarity.EPIC] = {
    {
      card = require("vibes.card.aura.preparations").new,
    },
  },
  [Rarity.LEGENDARY] = {
    {
      card = require("vibes.card.aura.harpoon").new,
    },
  },
}

cards[CardKind.ENHANCEMENT] = {
  [Rarity.COMMON] = {
    damage(Rarity.COMMON),
    range(Rarity.COMMON),
    attack_speed(Rarity.COMMON),
    critical(Rarity.COMMON),
    {
      card = require("vibes.card.enhancement.live-fast-die-young").new,
    },
    {
      card = require("vibes.card.aura.reinforcements").new,
    },
  },
  [Rarity.UNCOMMON] = {
    damage(Rarity.UNCOMMON),
    range(Rarity.UNCOMMON),
    attack_speed(Rarity.UNCOMMON),
    critical(Rarity.UNCOMMON),
    {
      card = require("vibes.card.enhancement.begins-possession").new,
    },
    {
      card = require("vibes.card.enhancement.burndown").new,
    },
  },
  [Rarity.RARE] = {
    {
      card = require("vibes.card.enhancement.danger-zone").new,
    },
    {
      card = require("vibes.card.enhancement.lonely-tower").new,
      level = { min = 1, max = 1 },
    },
    {
      card = require("vibes.card.enhancement.unlikely-meeting").new,
    },
    {
      card = require("vibes.card.enhancement.begins-preservations").new,
    },
    {
      card = BunnisWrath.new,
    },
    damage(Rarity.RARE),
    range(Rarity.RARE),
    attack_speed(Rarity.RARE),
    critical(Rarity.RARE),
  },
  [Rarity.EPIC] = {
    damage(Rarity.EPIC),
    range(Rarity.EPIC),
    attack_speed(Rarity.EPIC),
    critical(Rarity.EPIC),
  },
  [Rarity.LEGENDARY] = {
    damage(Rarity.LEGENDARY),
    range(Rarity.LEGENDARY),
    attack_speed(Rarity.LEGENDARY),
    critical(Rarity.LEGENDARY),
    {
      card = require("vibes.card.enhancement.begins-protection").new,
    },
  },
}

---@param kind CardKind
---@param rarity Rarity
---@param level_roll number: The roll for a card, from 0 to 1
cards.get_card = function(kind, rarity, level_roll)
  local card_list = cards[kind][rarity]
  local item = card_list[random[kind]:random(#card_list)]
  local card = item.card()
  if item.level then
    local level =
      math.ceil(item.level.min + (item.level.max - item.level.min) * level_roll)

    if card.level_up_to then
      card:level_up_to(level)
    end
  end

  if kind == CardKind.AURA then
    assert(
      rarity == card.rarity,
      "Aura card rarity mismatch: "
        .. card.name
        .. " Requested "
        .. rarity
        .. " Got "
        .. card.rarity
    )
  end

  return card
end
return cards
