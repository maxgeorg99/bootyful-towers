---@class enhancement.BeginsPreservations : vibes.EnhancementCard
---@field new fun(): enhancement.BeginsPreservations
---@field init fun(self: enhancement.BeginsPreservations)
---@field super vibes.EnhancementCard
local BeginsPreservations =
  class("enhancement.BeginsPreservations", { super = EnhancementCard })

local name = "Begin's Preservations"
local description =
  "Choose a random enhancement from target tower and save it on the original tower card that created it. Next time that specific tower card is played, the saved enhancement is applied."
local energy = 3
local texture = Asset.sprites.card_vibe_hoard
local duration = EffectDuration.END_OF_MAP

function BeginsPreservations:init()
  EnhancementCard.init(self, {
    name = name,
    description = description,
    energy = energy,
    texture = texture,
    duration = duration,
    hooks = {},
    rarity = Rarity.RARE,
  })
end

--- Play the Begin's Preservations card effect
function BeginsPreservations:play_effect_card()
  local target_tower = State.enhancement_target_towers[self]
  if target_tower and target_tower.tower then
    local tower = target_tower.tower

    -- Choose a random enhancement if any exist
    if #tower.enhancements > 0 then
      local random_index = math.random(1, #tower.enhancements)
      local chosen_enhancement = tower.enhancements[random_index]

      -- Find the original tower card that created this tower
      if tower.source_tower_card then
        -- Preserve the chosen enhancement on the original tower card
        tower.source_tower_card:preserve_enhancements { chosen_enhancement }
      end
    end
  end
end

---@param tower vibes.Tower
---@return boolean
function BeginsPreservations:is_active(tower)
  -- This card doesn't provide ongoing stats, only immediate effect
  return false
end

function BeginsPreservations:get_tower_operations()
  -- This card doesn't provide ongoing stats
  return {}
end

return BeginsPreservations
