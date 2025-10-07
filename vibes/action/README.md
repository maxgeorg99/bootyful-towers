# Pack Opening Actions

## Overview

Pack opening has been split into two completely separate action systems to handle the different UI flows and requirements for card packs vs gear packs.

## Action Types

### Card Pack Opening (`actions.CardPackOpening`)
- **File**: `vibes/action/card-pack-opening.lua`
- **Purpose**: Opens card packs (TOWER and MODIFIER packs)
- **UI Component**: `ui.components.pack.selection` (existing card selection UI)
- **Result**: Adds selected card to player's deck
- **Pack Type**: `vibes.CardPack`

### Gear Pack Opening (`actions.GearPackOpening`)  
- **File**: `vibes/action/gear-pack-opening.lua`
- **Purpose**: Opens gear packs containing unique gear items
- **UI Component**: `ui.components.pack.gear-selection` (specialized gear UI)
- **Result**: Adds selected gear to gear manager inventory
- **Pack Type**: `vibes.GearPack`

## Key Differences

### Card Packs
- Always contain exactly 3 cards
- Cards can be duplicated (multiple copies allowed)
- Uses existing card display components
- Adds to deck when selected
- Standard card selection interface

### Gear Packs
- Can contain 1-3 gear items (due to uniqueness constraint)
- Each gear can only be acquired once per game
- Uses specialized gear display components
- Adds to gear manager when selected
- Different visual layout optimized for gear

## Usage Examples

### Manual Action Creation
```lua
local CardPackOpening = require "vibes.action.card-pack-opening"
local GearPackOpening = require "vibes.action.gear-pack-opening"

-- Open a card pack
local card_action = CardPackOpening.new {
  pack = card_pack, -- vibes.CardPack
  on_complete = function()
    logger.info("Card pack opened")
  end
}

-- Open a gear pack  
local gear_action = GearPackOpening.new {
  pack = gear_pack, -- vibes.GearPack
  on_complete = function()
    logger.info("Gear pack opened")
  end
}
```

### Automatic Type Detection (Shop UI)
```lua
-- ShopUI uses polymorphic methods to detect pack type and route to correct action
function ShopUI:_purchase_pack(pack) -- pack is vibes.ShopPack
  local card_pack = pack:get_card_pack()
  local gear_pack = pack:get_gear_pack()
  
  if card_pack then
    -- Routes to CardPackOpening
    -- ... CardPackOpening.new { pack = card_pack }
  elseif gear_pack then
    -- Routes to GearPackOpening
    -- ... GearPackOpening.new { pack = gear_pack }
  end
end
```

## UI Components

### Card Pack UI
- `ui.components.pack.selection` - Main selection interface
- `ui.components.pack.card` - Individual card display
- Reuses existing card rendering system

### Gear Pack UI
- `ui.components.pack.gear-selection` - Main gear selection interface
- `ui.components.pack.gear-item` - Individual gear display
- Specialized for gear with different visual layout
- Shows gear kind, name, and visual indicators
- Color-coded by gear type

## Critical Separation

🚨 **THESE ACTIONS ARE COMPLETELY SEPARATE**
- Different classes for different pack types
- Different UI flows and components
- Different result handling (deck vs gear manager)
- No shared code paths between card and gear opening
- Allows for future specialized features for each type

This separation enables:
1. Specialized UI for each pack type
2. Different opening animations/effects
3. Type-specific validation and handling
4. Independent evolution of features
5. Clear separation of concerns
