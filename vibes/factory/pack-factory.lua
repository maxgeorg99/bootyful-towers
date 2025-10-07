local CardFactory = require "vibes.factory.card-factory"
local GearFactory = require "gear.factory"
local PackKinds = require "vibes.enum.pack-kind"

---@class (exact) vibes.ShopPack
---@field new fun(opts: vibes.ShopPack.Opts): vibes.ShopPack
---@field init fun(self: vibes.ShopPack, opts: vibes.ShopPack.Opts)
---@field cost number
---@field texture vibes.Texture
---@field name string
---@field description string
local ShopPack = class "vibes.ShopPack"

---@class (exact) vibes.ShopPack.Opts
---@field cost number
---@field texture vibes.Texture
---@field name string
---@field description string

--- Creates a new ShopPack (base class)
---@param opts vibes.ShopPack.Opts
function ShopPack:init(opts)
  validate(opts, {
    cost = "number",
    texture = "userdata",
    name = "string",
    description = "string",
  })

  self.cost = opts.cost
  self.texture = opts.texture
  self.name = opts.name
  self.description = opts.description
end

--- Check if this pack is a CardPack and return it if so
---@return vibes.CardPack?
function ShopPack:get_card_pack()
  local self_any = self --[[@as any]]
  if self_any.cards then
    return self --[[@as vibes.CardPack]]
  end
  return nil
end

--- Check if this pack is a GearPack and return it if so
---@return vibes.GearPack?
function ShopPack:get_gear_pack()
  local self_any = self --[[@as any]]
  if self_any.gear then
    return self --[[@as vibes.GearPack]]
  end
  return nil
end

---@class (exact) vibes.CardPack : vibes.ShopPack
---@field new fun(opts: vibes.CardPack.Opts): vibes.CardPack
---@field init fun(self: vibes.CardPack, opts: vibes.CardPack.Opts)
---@field cards vibes.Card[]
---@field kind PackKind
local CardPack = class("vibes.CardPack", { super = ShopPack })

---@class (exact) vibes.CardPack.Opts
---@field kind PackKind
---@field cards vibes.Card[]
---@field cost? number

---@class (exact) vibes.GearPack : vibes.ShopPack
---@field new fun(opts: vibes.GearPack.Opts): vibes.GearPack
---@field init fun(self: vibes.GearPack, opts: vibes.GearPack.Opts)
---@field gear gear.Gear[]
local GearPack = class("vibes.GearPack", { super = ShopPack })

---@class (exact) vibes.GearPack.Opts
---@field gear gear.Gear[]
---@field cost? number

-- Card pack configurations (TOWER and MODIFIER only)
local card_kind_to_texture = {
  [PackKinds.TOWER] = Asset.sprites.pack_tower,
  [PackKinds.MODIFIER] = Asset.sprites.pack_vibe,
}

local card_kind_to_name = {
  [PackKinds.TOWER] = "Tower Pack",
  [PackKinds.MODIFIER] = "Modifier Pack",
}

local card_kind_to_description = {
  [PackKinds.TOWER] = "Contains 3 random tower cards to place on your map",
  [PackKinds.MODIFIER] = "Contains 3 random modifier cards to enhance your towers",
}

-- Gear pack configurations
local gear_pack_texture = Asset.sprites.pack_gear
  or Asset.sprites.pack_orb
  or Asset.sprites.pack_vibe
local gear_pack_name = "Gear Pack"
local gear_pack_description =
  "Contains unique gear items to enhance your character"

--- Creates a new CardPack
---@param opts vibes.CardPack.Opts
function CardPack:init(opts)
  validate(opts, {
    cards = "table",
    kind = PackKind,
  })

  -- Card packs must contain exactly 3 cards
  assert(#opts.cards == 3, "card pack must contain exactly 3 cards")
  assert(opts.kind ~= PackKinds.GEAR, "use GearPack for gear, not CardPack")

  -- Initialize base class with card pack specific properties
  local base_opts = {
    cost = opts.cost or 150, -- Default cost if not provided
    texture = assert(
      card_kind_to_texture[opts.kind],
      "missing texture for card pack"
    ),
    name = assert(card_kind_to_name[opts.kind], "missing name for card pack"),
    description = assert(
      card_kind_to_description[opts.kind],
      "missing description for card pack"
    ),
  }
  ShopPack.init(self, base_opts)

  -- Set CardPack specific properties
  self.cards = opts.cards
  self.kind = opts.kind
end

--- Creates a new GearPack
---@param opts vibes.GearPack.Opts
function GearPack:init(opts)
  validate(opts, {
    gear = "table",
  })

  -- Gear packs may have fewer items due to uniqueness constraint
  assert(#opts.gear > 0, "gear pack must contain at least 1 item")

  -- Initialize base class with gear pack properties
  local base_opts = {
    cost = opts.cost or 150, -- Default cost if not provided
    texture = gear_pack_texture,
    name = gear_pack_name,
    description = gear_pack_description,
  }
  ShopPack.init(self, base_opts)

  -- Set GearPack specific properties
  self.gear = opts.gear
end

---@class vibes.PackFactory
---@field new fun(): vibes.PackFactory
---@field init fun(self: vibes.PackFactory)
local PackFactory = class "vibes.PackFactory"

function PackFactory:init() end

--- Generate a card pack of a specific type (TOWER or MODIFIER only)
---@param kind PackKind
---@return vibes.CardPack
function PackFactory:generate_card_pack(kind)
  assert(kind ~= PackKinds.GEAR, "use generate_gear_pack() for gear packs")

  local cards = {}
  local cost = 150

  -- Generate 3 cards of the specified type
  if kind == PackKinds.TOWER then
    -- Generate 3 tower cards using the new method
    for i = 1, 3 do
      local card = CardFactory.new_tower_card()
      table.insert(cards, card)
    end
  elseif kind == PackKinds.MODIFIER then
    -- Generate 3 enhancement cards using the new method
    for i = 1, 3 do
      local card = CardFactory.new_enhancement_card()
      table.insert(cards, card)
    end
  else
    error("Unknown card pack kind: " .. tostring(kind))
  end

  local pack = CardPack.new {
    cards = cards,
    cost = cost,
    kind = kind,
  }

  return pack
end

--- Generate a gear pack containing unique gear items
---@return vibes.GearPack
function PackFactory:generate_gear_pack()
  local gear_items = {}
  local cost = 150
  local already_selected = {} -- Track gear already selected for this pack

  -- Generate up to 3 unique gear items
  -- Note: Gear can never be duplicated - each gear can only be acquired once!
  -- This includes no duplicates within the same pack
  for i = 1, 3 do
    local available_gear = GearFactory:get_all_available_gear()

    -- Filter out gear already selected for this pack
    local filtered_gear = {}
    for _, gear in ipairs(available_gear) do
      if not already_selected[gear] then
        table.insert(filtered_gear, gear)
      end
    end

    if #filtered_gear == 0 then
      break -- No more unique gear available
    end

    -- Select random gear from filtered list
    local random_index = math.random(#filtered_gear)
    local selected_gear = filtered_gear[random_index]

    -- Mark as selected for this pack
    already_selected[selected_gear] = true
    table.insert(gear_items, selected_gear)
  end

  if #gear_items == 0 then
    error "Cannot generate gear pack - no gear available"
  end

  local pack = GearPack.new {
    gear = gear_items,
    cost = cost,
  }

  return pack
end

--- Check if a gear pack can be generated (i.e., if there's still gear available)
---@return boolean
function PackFactory:can_generate_gear_pack()
  return GearFactory:get_total_available_count() > 0
end

--- Get count of available gear items
---@return number
function PackFactory:get_available_gear_count()
  return GearFactory:get_total_available_count()
end

--- Generate a random card pack (TOWER or MODIFIER)
---@return vibes.CardPack
function PackFactory:generate_random_card_pack()
  local card_pack_kinds = { PackKinds.TOWER, PackKinds.MODIFIER }
  local kind = card_pack_kinds[math.random(#card_pack_kinds)]
  return self:generate_card_pack(kind)
end

--- Generate a random card pack (TOWER or MODIFIER)
---@return vibes.CardPack
function PackFactory:generate_trophy_card_pack()
  local card_pack_kinds = { PackKinds.MODIFIER }
  local kind = card_pack_kinds[math.random(#card_pack_kinds)]
  return self:generate_card_pack(kind)
end

return {
  PackFactory = PackFactory.new(),
  ShopPack = ShopPack,
  CardPack = CardPack,
  GearPack = GearPack,
}
