---@class vibes.Card : vibes.Class
---@field new fun(opts: vibes.CardOptions): vibes.Card
---@field init fun(self: self, opts: vibes.CardOptions)
---@field encode fun(self: vibes.Card): table<string, string>
---@field decode fun(self: vibes.Card, data: table<string, string>)
---@field get_description fun(self: vibes.Card): string
---@field _type "vibes.Card"
---@field name string
---@field description string|(fun(): string)
---@field kind CardKind
---@field after_play_kind CardAfterPlay
---@field level number
---@field energy number
---@field experience number
---@field rarity Rarity
---@field cost number
---@field position vibes.Position
---@field frame vibes.Texture
---@field hooks vibes.Hooks
local Card = class "vibes.Card"

local frames = {
  [Rarity.COMMON] = Asset.sprites.card_frame_common,
  [Rarity.UNCOMMON] = Asset.sprites.card_frame_uncommon,
  [Rarity.RARE] = Asset.sprites.card_frame_rare,
  [Rarity.EPIC] = Asset.sprites.card_frame_epic,
  [Rarity.LEGENDARY] = Asset.sprites.card_frame_legendary,
}

---@class (exact) vibes.CardOptions
---@field name string
---@field description string|fun(): string
---@field energy number
---@field kind CardKind
---@field texture vibes.Texture
---@field rarity Rarity
---@field after_play_kind CardAfterPlay
---@field hooks vibes.Hooks?

--- Creates a newRarity
---@param opts vibes.CardOptions
function Card:init(opts)
  opts.rarity = opts.rarity or Rarity.COMMON
  opts.after_play_kind = opts.after_play_kind or CardAfterPlay.DISCARD

  validate(opts, {
    name = "string",
    description = Either { "string", "function" },
    energy = "number",
    texture = "userdata",
    kind = CardKind,
    rarity = Rarity,
    after_play_kind = CardAfterPlay,
    hooks = "table?",
  })
  self.kind = opts.kind
  self.name = opts.name
  self.description = opts.description
  self.energy = opts.energy
  self.rarity = opts.rarity
  self.texture = opts.texture
  self.after_play_kind = opts.after_play_kind
  self.hooks = opts.hooks

  -- TODO: Shouldn't these be params?
  self.level = 1
  self.experience = 0
  self.cost = 150
end

function Card:get_description()
  if type(self.description) == "function" then
    return self.description()
  else
    return self.description --[[@as string]]
  end
end

--- @param other vibes.Card
--- @return boolean
function Card:eql(other) return self.id == other.id end

function Card:clone()
  return Card.new {
    name = self.name,
    description = self.description,
    energy = self.energy,
    texture = self.texture,
    kind = self.kind,
    rarity = self.rarity,
    after_play_kind = self.after_play_kind,
  }
end

---@param mouse vibes.Position
---@return boolean
function Card:contains(mouse)
  local pos = mouse:sub(self.position)
  return pos.x < Config.card.width
    and pos.y < Config.card.height
    and pos.x > 0
    and pos.y > 0
end

--- Type narrowing function to get a tower card
---@return vibes.TowerCard?
function Card:get_tower_card()
  if self.kind == CardKind.TOWER then
    return self --[[@as vibes.TowerCard]]
  end
  return nil
end

--- Type narrowing function to get a modifier
---@return vibes.EnhancementCard?
function Card:get_enhancement_card()
  if self.kind == CardKind.ENHANCEMENT then
    return self --[[@as vibes.EnhancementCard]]
  end
  return nil
end

--- Type narrowing function to get a tower effect
---@return vibes.AuraCard?
function Card:get_aura_card()
  logger.debug("Card:get_aura_card", self.kind)
  if self.kind == CardKind.AURA then
    return self --[[@as vibes.AuraCard]]
  end
  return nil
end

--- Abstract function to play upgrade animation.
--- This must be overridden by the child class.
function Card:play_upgrade_animation()
  error "Called base animation function for a card."
end

function Card:__tostring()
  return string.format("Card(%s, %s, %s)", self.kind, self.name, self.texture)
end

--- Encode this card for saving.
--- @return table<string, string>
function Card:encode()
  local description = self.description
  if type(self.description) == "function" then
    description = self.description()
  end
  return {
    name = self.name,
    description = description,
    energy = tostring(self.energy),
    kind = tostring(self.kind),
    after_play_kind = tostring(self.after_play_kind),
    level = tostring(self.level),
    experience = tostring(self.experience),
    rarity = tostring(self.rarity),
    cost = tostring(self.cost),
  }
end

--- Update a card from JSON (used for re-creating saved cards)
--- @param data table<string, string>
function Card:decode(data)
  self.name = data["name"]
  self.energy = tonumber(data["energy"]) or 2
  self.description = data["description"]
  self.kind = CardKind[data["kind"]]
  self.after_play_kind = CardAfterPlay[data["after_play_kind"]]
  self.level = tonumber(data["level"]) or 1
  self.experience = tonumber(data["experience"]) or 0
  self.rarity = Rarity[data["rarity"]]
  self.frame = frames[self.rarity]
end

function Card:get_name()
  local tower_card = self:get_tower_card()
  if tower_card then
    return tower_card.tower.name or self.name
  end

  if type(self.name) == "function" then
    return self.name()
  end
  return self.name
end

return Card
