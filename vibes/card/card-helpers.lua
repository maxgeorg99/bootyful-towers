---@class vibes.card.CardRarityColor
---@field text number[]  -- RGBA color values {r, g, b, a}
---@field bgcolor number[]  -- RGBA color values {r, g, b, a}

---@type table<Rarity, vibes.card.CardRarityColor>
local RarityColor = {
  [Rarity.COMMON] = {
    text = { 255 / 255, 255 / 255, 255 / 255, 255 / 255 },
    bgcolor = { 34 / 255, 51 / 255, 64 / 255, 250 / 255 },
  },
  [Rarity.UNCOMMON] = {
    text = { 0 / 255, 0 / 255, 0 / 255, 255 / 255 },
    bgcolor = { 156 / 255, 186 / 255, 168 / 255, 250 / 255 },
  },
  [Rarity.RARE] = {
    text = { 0 / 255, 0 / 255, 0 / 255, 255 / 255 },
    bgcolor = { 242 / 255, 194 / 255, 123 / 255, 250 / 255 },
  },
  [Rarity.EPIC] = {
    text = { 0 / 255, 0 / 255, 0 / 255, 255 / 255 },
    bgcolor = { 171 / 255, 178 / 255, 238 / 255, 250 / 255 },
  },
  [Rarity.LEGENDARY] = {
    text = { 0 / 255, 0 / 255, 0 / 255, 255 / 255 },
    bgcolor = { 242 / 255, 123 / 255, 123 / 255, 250 / 255 },
  },
}

return { RarityColor = RarityColor }
