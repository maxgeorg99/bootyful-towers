---@class vibes.UnlikelyMeetingCard : vibes.EnhancementCard
---@field new fun(): vibes.UnlikelyMeetingCard
---@field init fun(self: self)
---@field super vibes.EnhancementCard
---@field stunned_enemies table<vibes.Enemy, number> Track stunned enemies and their end time
---@field cooldown_end_time number Absolute time when cooldown ends
local UnlikelyMeetingCard = class(
  "vibes.unlikely-meeting-card",
  { super = require "vibes.card.enhancement" }
)

local name = "Unlikely Meeting"
local description =
  "When two enemies are within 100 units of each other in this tower's range, they both get stunned for 1 second. 1 second cooldown between activations."
local energy = 3
local texture = Asset.sprites.card_enhancement_unlikely_meeting
local duration = EffectDuration.END_OF_MAP

function UnlikelyMeetingCard:init()
  self.stunned_enemies = {}
  self.ignore_enemies = {}
  self.cooldown_end_time = 0

  require("vibes.card.enhancement").init(self, {
    name = name,
    description = description,
    energy = energy,
    texture = texture,
    duration = duration,
    hooks = {},
    rarity = Rarity.RARE,
  })
end

---@param tower vibes.Tower
---@return boolean
function UnlikelyMeetingCard:is_active(tower) return true end

---@param tower vibes.Tower
---@param dt number?
---@return tower.StatOperation[]
function UnlikelyMeetingCard:get_tower_operations(tower, dt)
  local current_time = TIME.now()

  -- Update stun timers - remove enemies whose stun time has expired

  for enemy, end_time in pairs(self.stunned_enemies) do
    if current_time >= end_time then
      self.stunned_enemies[enemy] = nil
      self.ignore_enemies[enemy] = true
    end
  end

  -- Only check for new stuns if cooldown is finished and no enemies are currently stunned
  if
    current_time >= self.cooldown_end_time
    and next(self.stunned_enemies) == nil
  then
    -- Find enemies within tower range
    local enemies_in_range = {}
    local tower_range = tower:get_range_in_distance()

    for _, enemy in ipairs(State.enemies) do
      local distance = enemy.position:distance(tower.position)
      if distance <= tower_range and not self.ignore_enemies[enemy] then
        table.insert(enemies_in_range, enemy)
      end
    end

    -- Check for enemies within 100 units of each other
    local stun_distance = 100
    for i = 1, #enemies_in_range do
      for j = i + 1, #enemies_in_range do
        local enemy1 = enemies_in_range[i]
        local enemy2 = enemies_in_range[j]
        local distance_between = enemy1.position:distance(enemy2.position)

        if distance_between <= stun_distance then
          -- Stun both enemies for 1 second and start cooldown
          local stun_end_time = current_time + 1.0
          self.stunned_enemies[enemy1] = stun_end_time
          self.stunned_enemies[enemy2] = stun_end_time
          self.cooldown_end_time = current_time + 1.0
          -- Break out of both loops since we can only stun one pair at a time
          goto stun_applied
        end
      end
    end
    ::stun_applied::
  end

  return {}
end

--- Get enemy operations to apply stun effect
---@param enemy vibes.Enemy
---@return enemy.StatOperation[]
function UnlikelyMeetingCard:get_enemy_operations(enemy)
  if self.stunned_enemies[enemy] then
    -- Apply massive speed reduction to effectively stun the enemy
    return {
      EnemyStatOperation.new {
        field = EnemyStatField.SPEED,
        operation = StatOperation.new {
          kind = StatOperationKind.MUL_MULT,
          value = 0.01, -- Reduce speed to 1% (effectively stunned)
        },
      },
    }
  end

  return {}
end

return UnlikelyMeetingCard
