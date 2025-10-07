# Pack Factory System

## Overview

The pack factory system generates different types of packs with completely separate paths and handling. Card packs and gear packs are distinct types that cannot overlap.

## Pack Types

### Base Class: Shop Pack (`vibes.ShopPack`)
- **Shared Properties**: `cost`, `texture`, `name`, `description`
- Base class that all shop packs inherit from
- Handles common pack functionality
- **Polymorphic Methods**: 
  - `get_card_pack()` - Returns `CardPack` if this is a card pack, `nil` otherwise
  - `get_gear_pack()` - Returns `GearPack` if this is a gear pack, `nil` otherwise

### Card Packs (`vibes.CardPack` extends `vibes.ShopPack`)
- **Tower Packs**: Contains 3 random tower cards
- **Modifier Packs**: Contains 3 random enhancement cards  
- Always contain exactly 3 cards
- Use standard card generation through `CardFactory`
- **Additional Properties**: `cards[]`, `kind`

### Gear Packs (`vibes.GearPack` extends `vibes.ShopPack`)
- Contains unique gear items (1-3 items depending on availability)
- Each gear can only be acquired once per game session
- Use gear generation through `GearFactory`
- **Cannot be mixed with card packs**
- **Additional Properties**: `gear[]`

## Critical Separation

🚨 **CARD PACKS AND GEAR PACKS ARE COMPLETELY SEPARATE**
- Different classes: `vibes.CardPack` vs `vibes.GearPack`
- Different generation methods: `generate_card_pack()` vs `generate_gear_pack()`
- Different UI flows (gear packs will open different screens)
- No overlap in generation paths

## Usage Examples

```lua
local factory = require("vibes.factory.pack-factory")

-- Generate specific card packs
local tower_pack = factory.PackFactory:generate_card_pack(PackKinds.TOWER)
local modifier_pack = factory.PackFactory:generate_card_pack(PackKinds.MODIFIER)

-- Generate random card pack
local random_card_pack = factory.PackFactory:generate_random_card_pack()

-- Generate gear pack (completely separate)
if factory.PackFactory:can_generate_gear_pack() then
  local gear_pack = factory.PackFactory:generate_gear_pack()
  -- gear_pack.gear contains the actual gear items
end

-- Polymorphic pack handling
local some_pack = factory.PackFactory:generate_random_card_pack() -- vibes.ShopPack
local card_pack = some_pack:get_card_pack() -- vibes.CardPack? 
local gear_pack = some_pack:get_gear_pack() -- vibes.GearPack?

if card_pack then
  print("This is a card pack with", #card_pack.cards, "cards")
elseif gear_pack then
  print("This is a gear pack with", #gear_pack.gear, "gear items")
end

-- Check availability
local gear_available = factory.PackFactory:get_available_gear_count()
```

## API Reference

### PackFactory Methods

#### Card Pack Generation
- `generate_card_pack(kind)` - Generate specific card pack (TOWER or MODIFIER)
- `generate_random_card_pack()` - Generate random card pack

#### Gear Pack Generation  
- `generate_gear_pack()` - Generate gear pack with unique items
- `can_generate_gear_pack()` - Check if gear pack can be generated
- `get_available_gear_count()` - Get count of available gear

### Pack Classes
- `vibes.ShopPack` - Base class with `cost`, `texture`, `name`, `description`
- `vibes.CardPack` - Extends `ShopPack`, adds `cards[]` and `kind`
- `vibes.GearPack` - Extends `ShopPack`, adds `gear[]` (no `kind` field)

## Future Extensions

When adding new pack types:
1. Determine if it's a card-based or gear-based pack
2. Add to appropriate generation path
3. Ensure no overlap between different pack systems
4. Add specific UI handling for the pack type
