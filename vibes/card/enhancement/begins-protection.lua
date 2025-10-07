---@class enhancement.BeginsProtection : vibes.EnhancementCard
---@field new fun(): enhancement.BeginsProtection
---@field init fun(self: enhancement.BeginsProtection)
---@field super vibes.EnhancementCard
local BeginsProtection =
  class("enhancement.BeginsProtection", { super = EnhancementCard })

local name = "Begin's Protection"
local description =
  "Save all enhancements from target tower without removing them on the original tower card that created it. Next time that specific tower card is played, all saved enhancements are applied."
local energy = 4
local texture = Asset.sprites.card_vibe_hoard
local duration = EffectDuration.END_OF_MAP

function BeginsProtection:init()
  EnhancementCard.init(self, {
    name = name,
    description = description,
    energy = energy,
    texture = texture,
    duration = duration,
    hooks = {},
    rarity = Rarity.LEGENDARY,
  })
end

--- Play the Begin's Protection card effect
function BeginsProtection:play_effect_card()
  local target_tower = State.enhancement_target_towers[self]
  if target_tower and target_tower.tower then
    local tower = target_tower.tower

    -- Save all current enhancements without removing them
    local enhancements_to_preserve = {}
    for _, enhancement in ipairs(tower.enhancements) do
      table.insert(enhancements_to_preserve, enhancement)
    end

    -- Find the original tower card that created this tower
    if #enhancements_to_preserve > 0 and tower.source_tower_card then
      -- Preserve the enhancements on the original tower card (without removing from tower)
      tower.source_tower_card:preserve_enhancements(enhancements_to_preserve)
    end
  end
end

---@param tower vibes.Tower
---@return boolean
function BeginsProtection:is_active(tower)
  -- This card doesn't provide ongoing stats, only immediate effect
  return false
end

function BeginsProtection:get_tower_operations()
  -- This card doesn't provide ongoing stats
  return {}
end

return BeginsProtection
