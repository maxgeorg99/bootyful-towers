---@class aura.SizeDoubler : vibes.AuraCard
---@field new fun(): aura.SizeDoubler
---@field init fun(self: aura.SizeDoubler)
---@field super vibes.AuraCard
local SizeDoubler = class("aura.SizeDoubler", { super = AuraCard })

local name = "Size Doubler"
local description =
  "Every time you inflict damage to an enemy, increase their size by 10%."
local energy = 2
local texture = Asset.sprites.card_enhancement_dam -- Using dam texture as placeholder
local duration = EffectDuration.END_OF_MAP

-- Global flag to prevent multiple listeners and recursive calls
local size_doubler_listener_active = false
local size_doubler_processing = false

--- Creates a new SizeDoubler aura
function SizeDoubler:init()
  AuraCard.init(self, {
    name = name,
    description = description,
    energy = energy,
    texture = texture,
    duration = duration,
    hooks = {},
    rarity = Rarity.RARE,
  })
end

--- Play the Size Doubler card effect
function SizeDoubler:play_effect_card()
  -- Only set up the listener if it hasn't been set up already
  if not size_doubler_listener_active then
    logger.info "Size Doubler: Setting up enemy damage listener"
    size_doubler_listener_active = true

    EventBus:listen_enemy_damage(function(event)
      ---@cast event vibes.event.EnemyDamage

      -- Prevent recursive calls
      if size_doubler_processing then
        return
      end

      size_doubler_processing = true

      local enemy = event.enemy

      logger.info(
        "Size Doubler: Enemy took damage, increasing size from %dx%d to %dx%d",
        enemy.physical_width,
        enemy.physical_height,
        enemy.physical_width * 1.1,
        enemy.physical_height * 1.1
      )

      -- Increase the enemy's physical size by 10%
      enemy:double_physical_size()

      logger.info(
        "Size Doubler: Enemy size after increase: %dx%d, scale: %f",
        enemy.physical_width,
        enemy.physical_height,
        enemy.scale
      )

      size_doubler_processing = false
    end)
  else
    logger.info "Size Doubler: Listener already active, skipping setup"
  end
end

--- Whether this aura applies to the given tower (not applicable for this aura)
---@param _tower vibes.Tower
---@return boolean
function SizeDoubler:is_active_on_tower(_tower) return false end

--- Tower operations granted by this aura (none)
---@param _tower vibes.Tower
---@return tower.StatOperation[]
function SizeDoubler:get_tower_operations(_tower) return {} end

return SizeDoubler
