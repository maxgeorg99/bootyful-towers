---@class vibes.Color
---@field new fun(r: number, g: number, b: number, a?: number): vibes.Color
---@field init fun(self: vibes.Color, r: number, g: number, b: number, a?: number)
Color = class "vibes.Color"

function Color:init(r, g, b, a)
  a = F.if_nil(a, 1)

  if r > 1 then
    r = r / 255
  end
  if g > 1 then
    g = g / 255
  end
  if b > 1 then
    b = b / 255
  end
  if a > 1 then
    a = a / 255
  end

  self[1] = r
  self[2] = g
  self[3] = b
  self[4] = a
end

---@return table
function Color:get() return { self[1], self[2], self[3], self[4] } end

---@param alpha any
---@return table
function Color:opacity(alpha)
  return { self[1], self[2], self[3], self[4] * alpha }
end

function Color:average(other, weight)
  return Color.new(
    (self[1] * weight + other[1] * (1 - weight)) / 2,
    (self[2] * weight + other[2] * (1 - weight)) / 2,
    (self[3] * weight + other[3] * (1 - weight)) / 2,
    (self[4] * weight + other[4] * (1 - weight)) / 2
  )
end

---@class vibes.Colors
Colors = {
  rarity = {
    [Rarity.COMMON] = Color.new(192, 192, 192), -- Soft Silver/Grey
    [Rarity.UNCOMMON] = Color.new(30, 255, 0), -- Vivid Green
    [Rarity.RARE] = Color.new(0, 112, 221), -- Deep Blue (WoW Rare)
    [Rarity.EPIC] = Color.new(163, 53, 238), -- Vibrant Purple (WoW Epic)
    [Rarity.LEGENDARY] = Color.new(255, 128, 0), -- Bright Orange (WoW Legendary)
  },
  red = Color.new(221, 15, 15),
  dark_red = Color.new(174, 40, 51),
  black = Color.new(0, 0, 0),
  white = Color.new(1, 1, 1),
  slate = Color.new(34, 51, 64),
  gray = Color.new(67, 67, 67),
  light_gray = Color.new(142, 142, 142),
  burgundy = Color.new(107, 50, 46),
  dark_burgundy = Color.new(71, 31, 28),
  blue = Color.new(57, 131, 217),
  can_select = Color.new(0, 1, 0),
  green = Color.new(30, 255, 0),
  yellow = Color.new(255, 255, 0),
  purple = Color.new(128, 0, 128),
  brown = Color.new(102, 51, 0),
  orange = Color.new(255, 165, 0),
  gold = Color.new(255, 215, 0),
  dark_gold = Color.new(184, 134, 11),
  button_brown = Color.new(69, 37, 49),
}
