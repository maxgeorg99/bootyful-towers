local Tower = require "vibes.tower.base"

---@class (exact) vibes.TowerCard : vibes.Card
---@field new fun(opts: vibes.TowerCardOptions): vibes.TowerCard
---@field init fun(self: vibes.TowerCard, opts: vibes.TowerCardOptions)
---@field encode fun(self: self): table<string, string>
---@field decode fun(self: self, data: table<string, string>)
---@field _type "vibes.base-tower-card"
---@field tower vibes.Tower
---@field preserved_enhancements vibes.EnhancementCard[] Enhancements preserved on this specific tower card
local TowerCard = class("vibes.tower-card", { super = Card })
Encodable(TowerCard, "vibes.TowerCard", "vibes.card.base")

---@class (exact) vibes.TowerCardOptions
---@field name string
---@field description string
---@field energy number
---@field texture vibes.Texture
---@field rarity Rarity
---@field tower vibes.Tower

--- Creates a new TowerCard
function TowerCard:init(opts)
  Card.init(self, {
    name = opts.name,
    description = opts.description,
    energy = opts.energy,
    texture = opts.texture,
    rarity = opts.rarity,
    kind = CardKind.TOWER,
    after_play_kind = CardAfterPlay.EXHAUST,
  })

  self.tower = opts.tower
  if self.tower.name then
    self.name = self.tower.name
  end

  if self.tower.description then
    self.description = self.tower.description
  end
  self.preserved_enhancements = {}
end

--- Level a tower card up to a certain level, randomly apply upgrades.
---@param level number
function TowerCard:level_up_to(level)
  while self.tower.level < level do
    self.tower.experience_manager:level_up { interactive = false }
  end

  if self.tower.name then
    self.name = self.tower.name
  end

  if self.tower.description then
    self.description = self.tower.description
  end
end

--- Add preserved enhancements to this tower card
---@param enhancements vibes.EnhancementCard[]
function TowerCard:preserve_enhancements(enhancements)
  for _, enhancement in ipairs(enhancements) do
    table.insert(self.preserved_enhancements, enhancement)
  end
end

--- Check if this tower card has preserved enhancements
---@return boolean
function TowerCard:has_preserved_enhancements()
  return #self.preserved_enhancements > 0
end

--- Get and consume preserved enhancements from this tower card
---@return vibes.EnhancementCard[]
function TowerCard:get_preserved_enhancements()
  local preserved = self.preserved_enhancements
  self.preserved_enhancements = {}
  return preserved
end

--- Get the card description, including preserved enhancement information
---@return string
function TowerCard:get_description()
  local base_description = self.description
  if type(base_description) == "function" then
    base_description = base_description()
  end

  if self:has_preserved_enhancements() then
    local preserved_count = #self.preserved_enhancements
    local preservation_text = string.format(
      "\n\n[Preserved: %d enhancement%s]",
      preserved_count,
      preserved_count == 1 and "" or "s"
    )
    return base_description .. preservation_text
  end

  return base_description
end

return TowerCard
