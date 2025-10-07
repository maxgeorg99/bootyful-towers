---@class vibes.BurndownCard : vibes.EnhancementCard
---@field new fun(): vibes.BurndownCard
---@field init fun(self: self)
---@field remaining_damage number
local BurndownCard =
  class("vibes.burndown-card", { super = require "vibes.card.enhancement" })

Encodable(
  BurndownCard,
  "vibes.BurndownCard",
  "vibes.card.enhancement",
  ---@param self vibes.BurndownCard
  ---@return table<string, string>
  function(self)
    return {
      remaining_damage = tostring(self.remaining_damage),
    }
  end,
  ---@param self vibes.BurndownCard
  ---@param data table<string, string>
  function(self, data)
    self.remaining_damage = tonumber(data.remaining_damage) or 100
  end
)

local name = "Burndown"
local energy = 2
local texture = Asset.sprites.card_enhancement_burndown
local duration = EffectDuration.END_OF_MAP

local damage_decrease = 1
local starting_damage = 100

function BurndownCard:init()
  EnhancementCard.init(self, {
    name = name,
    description = function()
      return string.format(
        "Gives +{damage:%d}, but loses {damage:%d} damage after each attack. When it reaches 0, the tower is trashed.",
        self.remaining_damage,
        damage_decrease
      )
    end,
    energy = energy,
    texture = texture,
    duration = duration,
    hooks = {
      after_tower_attack = function(self_card, tower)
        if table.find(tower.enhancements, self_card) then
          -- Decrease the remaining damage after each attack
          if self_card.remaining_damage > 0 then
            self_card.remaining_damage = self_card.remaining_damage
              - damage_decrease
          end

          if self_card.remaining_damage <= 0 then
            table.remove_item(tower.enhancements, self_card)

            -- TODO: THIS
            local element = GAME.ui:find_placed_tower(tower)
            GAME.ui.enemy_tower_children:remove_child(element)

            GameAnimationSystem:play_fire(tower.position)
          end
        end
      end,
    },
    rarity = Rarity.UNCOMMON,
  })

  self.remaining_damage = starting_damage
end

---@param tower vibes.Tower
---@return boolean
function BurndownCard:is_active(tower) return true end

function BurndownCard:get_tower_operations()
  -- Only provide bonus if we have damage remaining
  if self.remaining_damage <= 0 then
    return {}
  end

  return {
    TowerStatOperation.new {
      field = TowerStatField.DAMAGE,
      operation = StatOperation.new {
        kind = StatOperationKind.ADD_BASE,
        value = self.remaining_damage,
      },
    },
  }
end

return BurndownCard
