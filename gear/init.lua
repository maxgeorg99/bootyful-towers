local Hooks = require "vibes.hooks"

--[[

Gear:

Clothing Gear:
  - 1 hat slot
  - 1 shirt slot
  - 1 pants slot
  - 1 shoes slot

Jewelry Gear:
  - 1 necklace slot
  - 2 ring slot

Tool Slot
  - 2 tool slots


Inventory (UNUSED) Slots:
- 4 slots, any gear type

]]

---@class gear.Gear.Opts
---@field name string
---@field description ui.Text.Item[]
---@field kind GearKind
---@field rarity Rarity
---@field slot GearSlot?
---@field texture vibes.Texture
---@field hooks vibes.effect.HookParams
---@field is_active_on_tower? fun(self: gear.Gear, tower: vibes.Tower): boolean
---@field get_tower_operations? fun(self: gear.Gear, tower: vibes.Tower): tower.StatOperation[]
---@field is_active_on_enemy? fun(self: gear.Gear, enemy: vibes.Enemy): boolean
---@field get_enemy_operations? fun(self: gear.Gear, enemy: vibes.Enemy): enemy.StatOperation[]
---@field get_selling_price? fun(self: gear.Gear, price: number): number

---@class gear.Gear: vibes.Class
---@field new fun(opts: gear.Gear.Opts): gear.Gear
---@field init fun(self: gear.Gear, opts: gear.Gear.Opts)
---@field name string
---@field description ui.Text.Item[]
---@field kind GearKind
---@field rarity Rarity
---@field slot GearSlot?
---@field texture vibes.Texture
---@field hooks vibes.Hooks
--
-- Tower Fields
---@field is_active_on_tower fun(self: gear.Gear, tower: vibes.Tower): boolean
---@field get_tower_operations fun(self: gear.Gear, tower: vibes.Tower): tower.StatOperation[]
--
-- Enemy Fields
---@field is_active_on_enemy fun(self: gear.Gear, enemy: vibes.Enemy): boolean
---@field get_enemy_operations fun(self: gear.Gear, enemy: vibes.Enemy): enemy.StatOperation[]
---
---@field _get_selling_price? fun(self: gear.Gear, price: number): number
local Gear = class("gear.Gear", {
  abstract = {
    -- -- Tower Fields
    -- is_active_on_tower = true,
    -- get_tower_operations = true,
    --
    -- -- Enemy Fields
    -- is_active_on_enemy = true,
    -- get_enemy_operations = true,
  },
  get_id = function(self) return string.format("gear:%s", self.name) end,
})

function Gear:init(opts)
  opts.rarity = opts.rarity or Rarity.COMMON

  validate(opts, {
    name = "string",
    kind = GearKind,
    rarity = Rarity,
    slot = Optional { GearSlot },
    texture = "userdata",
    hooks = "table",
  })

  self.name = opts.name
  self.description = opts.description
  self.kind = opts.kind
  self.rarity = opts.rarity
  self.slot = opts.slot
  self.texture = opts.texture
  self.hooks = Hooks.new(opts.hooks)
  self._get_selling_price = opts.get_selling_price

  self._is_active_on_enemy = opts.is_active_on_enemy
  self._get_enemy_operations = opts.get_enemy_operations
  self._is_active_on_tower = opts.is_active_on_tower
  self._get_tower_operations = opts.get_tower_operations
end

---@class gear.Hat : gear.Gear
---@class gear.Shirt : gear.Gear
---@class gear.Pants : gear.Gear
---@class gear.Shoes : gear.Gear
---@class gear.Necklace : gear.Gear
---@class gear.Ring : gear.Gear
---@class gear.Tool : gear.Gear

function Gear:is_active_on_tower(_tower)
  if self._is_active_on_tower then
    return self:_is_active_on_tower(_tower)
  end

  return false
end

function Gear:get_tower_operations(_tower)
  if self._get_tower_operations then
    return self:_get_tower_operations(_tower)
  end
  return {}
end

function Gear:is_active_on_enemy(_enemy)
  if self._is_active_on_enemy then
    return self:_is_active_on_enemy(_enemy)
  end
  return false
end

function Gear:get_enemy_operations(_enemy)
  if self._get_enemy_operations then
    return self:_get_enemy_operations(_enemy)
  end
  return {}
end

function Gear:get_selling_price(price)
  if self._get_selling_price then
    return self:_get_selling_price(price)
  end

  return price
end

return Gear
