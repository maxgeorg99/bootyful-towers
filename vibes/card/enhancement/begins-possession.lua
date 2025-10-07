---@class enhancement.BeginsPossession : vibes.EnhancementCard
---@field new fun(): enhancement.BeginsPossession
---@field init fun(self: enhancement.BeginsPossession)
---@field super vibes.EnhancementCard
local BeginsPossession =
  class("enhancement.BeginsPossession", { super = EnhancementCard })

local name = "Begin's Possession"
local description =
  "Remove all enhancements from target tower and save them on the original tower card that created it. Next time that specific tower card is played, all saved enhancements are applied."
local energy = 2
local texture = Asset.sprites.card_vibe_hoard
local duration = EffectDuration.END_OF_MAP

function BeginsPossession:init()
  EnhancementCard.init(self, {
    name = name,
    description = description,
    energy = energy,
    texture = texture,
    duration = duration,
    hooks = {},
    rarity = Rarity.UNCOMMON,
  })
end

--- Play the Begin's Possession card effect
function BeginsPossession:play_effect_card()
  local target_tower = State.enhancement_target_towers[self]
  if target_tower and target_tower.tower then
    local tower = target_tower.tower

    -- Save all current enhancements
    local enhancements_to_preserve = {}
    for _, enhancement in ipairs(tower.enhancements) do
      table.insert(enhancements_to_preserve, enhancement)
    end

    -- Find the original tower card that created this tower
    if #enhancements_to_preserve > 0 and tower.source_tower_card then
      -- Preserve the enhancements on the original tower card
      tower.source_tower_card:preserve_enhancements(enhancements_to_preserve)
      -- Remove all enhancements from the tower
      tower.enhancements = {}
      tower:_update_stats()
    end
  end
end

---@param tower vibes.Tower
---@return boolean
function BeginsPossession:is_active(tower)
  -- This card doesn't provide ongoing stats, only immediate effect
  return false
end

function BeginsPossession:get_tower_operations()
  -- This card doesn't provide ongoing stats
  return {}
end

return BeginsPossession
