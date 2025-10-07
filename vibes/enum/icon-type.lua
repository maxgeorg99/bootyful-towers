---@diagnostic disable-next-line: duplicate-doc-alias
---@enum IconType
local icon_type = {
  SKULL = "SKULL",
  SWORD = "SWORD",
  SHIELD = "SHIELD",
  HEART = "HEART",
  BROKEN_HEART = "BROKEN_HEART",
  UPGRADE = "UPGRADE",
  DOWNGRADE = "DOWNGRADE",
  HEADS = "HEADS",
  TAILS = "TAILS",
  DICE = "DICE",
  REROLL = "REROLL",
  CROWN = "CROWN",

  SPEED = "SPEED",
  BOW = "BOW",
  ESCAPE_KEY = "ESCAPE_KEY",
  RIGHT_CLICK = "RIGHT_CLICK",
  DISCARD = "DISCARD",
  NOCARD = "NOCARD",
  DOWNARROW = "DOWNARROW",
  UP_ARROW = "UP_ARROW",
  DOWN_ARROW = "DOWN_ARROW",

  FIRE = "FIRE",
  ENHANCE = "ENHANCE",
  AURA = "AURA",
  CHANCE = "CHANCE",
  DAMAGE = "DAMAGE",
  ENERGY = "ENERGY",
  GOLD = "GOLD",
  RANGE = "RANGE",
  POISON = "POISON",
  TOWER = "TOWER",
  MULTI = "MULTI",
  ATTACKSPEED = "ATTACKSPEED",
  DURABILITY = "DURABILITY",

  DECK = "DECK",
  DECKDISCARD = "DECKDISCARD",
  DECKEXHAUST = "DECKEXHAUST",
}

---@diagnostic disable-next-line: duplicate-doc-alias
---@enum IconType
return require("vibes.enum").new("IconType", icon_type)
