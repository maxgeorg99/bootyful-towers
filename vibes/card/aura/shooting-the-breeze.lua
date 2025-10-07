---@class aura.ShootingTheBreeze : vibes.AuraCard
---@field new fun(): aura.ShootingTheBreeze
---@field init fun(self: aura.ShootingTheBreeze)
---@field cards_discarded number
local ShootingTheBreeze =
  class("vibes.cards.ShootingTheBreeze", { super = AuraCard })
Encodable(
  ShootingTheBreeze,
  "vibes.cards.ShootingTheBreeze",
  "vibes.card.base-aura-card"
)

local name = "Shooting the Breeze"
local description = "Archer towers gain +1 damage for each card discarded this map"
local texture = Asset.sprites.card_vibe_shooting_the_breeze
local duration = EffectDuration.END_OF_MAP

---Creates a new Shooting the Breeze aura card
function ShootingTheBreeze:init()
  AuraCard.init(self, {
    name = name,
    description = description,
    energy = 1,
    texture = texture,
    duration = duration,
    rarity = Rarity.UNCOMMON,
    hooks = {
      on_card_discarded = function(self, card)
        self.cards_discarded = self.cards_discarded + 1
        logger.debug(
          "Shooting the Breeze: Card discarded, total discards now: %d",
          self.cards_discarded
        )
      end,
    },
  })

  self.cards_discarded = 0
end

--- Play the Shooting the Breeze card effect
function ShootingTheBreeze:play_effect_card()
  logger.info(
    "Shooting the Breeze: Aura activated - archer towers will gain +1 damage per discard"
  )
end

--- Whether this aura applies to the given tower (applies to archer towers)
---@param tower vibes.Tower
---@return boolean
function ShootingTheBreeze:is_active_on_tower(tower)
  -- Check if the tower is an archer tower by checking its type
  local ArcherTower = require "vibes.tower.tower-archer"
  return not not ArcherTower.is(tower)
end

--- Tower operations granted by this aura (damage boost for archer towers)
---@param tower vibes.Tower
---@return tower.StatOperation[]
function ShootingTheBreeze:get_tower_operations(tower)
  if not self:is_active_on_tower(tower) then
    return {}
  end

  -- Add 1 damage per card discarded
  if self.cards_discarded > 0 then
    return {
      TowerStatOperation.base_damage(self.cards_discarded),
    }
  end

  return {}
end

--- Whether this aura applies to the given enemy (not applicable for this aura)
---@param _enemy vibes.Enemy
---@return boolean
function ShootingTheBreeze:is_active_on_enemy(_enemy) return false end

--- Enemy operations granted by this aura (none)
---@param _enemy vibes.Enemy
---@return enemy.StatOperation[]
function ShootingTheBreeze:get_enemy_operations(_enemy) return {} end

return ShootingTheBreeze
