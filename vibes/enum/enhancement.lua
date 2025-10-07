--[[

There are two types of enhancements, but it may be easier to think of it as
three types of enhancements.

1. physical enhancements
 - health, speed
2. physical resistances
 - light armor, heavy armor, poison
2(3?). elemental resistances
 - fire, lightning, air, water, (earth?)

That means towers can come with all resistance type of damage.  I don't think there should be a _no_ type of damage.
- basic arrow towers, they can be light damage
- catapults / whatever can be heavy damage
- arrow towers with poison arrows would do 2 types of damage, light + poison dot

The general proposal is that enemies have certain enhancement and weakness affinities
- bats
  - enhancements: speed
  - resistances: water, poison
  - weakness: heavy, air

...

Then there are level buffs
- they can really be any of the three applied to all enemies.  This will become
  more interesting as time goes on for the later levels.

--]]

---@diagnostic disable-next-line: duplicate-doc-alias
---@enum EnemyEnhancements
local enemy_enhancements = {
  SPEED = "SPEED",
  HEALTH = "HEALTH",
  LIGHT_SHIELD = "LIGHT_SHIELD",
  HEAVY_SHIELD = "HEAVY_SHIELD",
  FIRE = "FIRE",
  POISON = "POISON",
  ICE = "ICE",
  AIR = "AIR",
  WATER = "WATER",
}

---@diagnostic disable-next-line: duplicate-doc-alias
---@enum EnemyEnhancements
return require("vibes.enum").new("Enhancement", enemy_enhancements)
